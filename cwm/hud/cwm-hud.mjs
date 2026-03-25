#!/usr/bin/env node
/**
 * CWM HUD - folder, git branch, context bar, call counts, plan status, 5h rate limit
 */

import { execSync } from "node:child_process";
import { basename } from "node:path";
import { existsSync, statSync, openSync, readSync, closeSync, readdirSync, readFileSync } from "node:fs";
import { createReadStream } from "node:fs";
import { createInterface } from "node:readline";
import { join } from "node:path";

const MAX_TAIL_BYTES = 512 * 1024;

const C_RESET = "\x1b[0m";
const C_ACCENT = "\x1b[38;5;173m";
const C_BAR_EMPTY = "\x1b[38;5;238m";
const C_GRAY = "\x1b[38;5;245m";
const C_GREEN = "\x1b[38;5;76m";
const C_YELLOW = "\x1b[33m";
const C_RED = "\x1b[38;5;203m";

function renderContextBar(pct, maxK) {
  const barWidth = 10;
  const clamped = Math.min(pct, 100);
  let bar = "";
  for (let i = 0; i < barWidth; i++) {
    const barStart = i * 10;
    const progress = clamped - barStart;
    if (progress >= 8) {
      bar += `${C_ACCENT}\u2588${C_RESET}`;
    } else if (progress >= 3) {
      bar += `${C_ACCENT}\u2584${C_RESET}`;
    } else {
      bar += `${C_BAR_EMPTY}\u2591${C_RESET}`;
    }
  }
  return `${bar} ${C_GRAY}${pct}% of ${maxK}k${C_RESET}`;
}

function getPlanStatus(cwd) {
  const plansDir = join(cwd, "docs", "plans");
  if (!existsSync(plansDir)) return "";

  let active = 0, pending = 0, complete = 0, activeName = "";
  try {
    const entries = readdirSync(plansDir, { withFileTypes: true });
    for (const entry of entries) {
      if (!entry.isDirectory()) continue;
      const statusFile = join(plansDir, entry.name, ".status");
      if (!existsSync(statusFile)) continue;
      const status = readFileSync(statusFile, "utf-8").trim();
      if (status === "active") { active++; activeName = entry.name; }
      else if (status === "pending") pending++;
      else if (status === "complete") complete++;
    }
  } catch { return ""; }

  if (active > 0) {
    return `${C_YELLOW}\u{1F4CB} ${activeName}${C_RESET}`;
  } else if (pending > 0) {
    return `${C_RED}\u{1F4CB} ${pending} pending${C_RESET}`;
  } else if (complete > 0) {
    return `${C_GREEN}\u2713 ${complete} done${C_RESET}`;
  }
  return "";
}

async function countCalls(transcriptPath) {
  let toolCalls = 0, agentCalls = 0, skillCalls = 0;
  if (!transcriptPath || !existsSync(transcriptPath)) return { toolCalls, agentCalls, skillCalls };

  try {
    const stat = statSync(transcriptPath);
    const lines = stat.size > MAX_TAIL_BYTES
      ? readTailLines(transcriptPath, stat.size, MAX_TAIL_BYTES)
      : await readAllLines(transcriptPath);

    for (const line of lines) {
      if (!line.trim()) continue;
      try {
        const entry = JSON.parse(line);
        const content = entry.message?.content;
        if (!content || !Array.isArray(content)) continue;
        for (const block of content) {
          if (block.type === "tool_use" && block.name) {
            toolCalls++;
            if (block.name === "Task" || block.name === "proxy_Task" || block.name === "Agent") {
              agentCalls++;
            } else if (block.name === "Skill" || block.name === "proxy_Skill") {
              skillCalls++;
            }
          }
        }
      } catch { /* skip malformed */ }
    }
  } catch { /* ignore */ }

  return { toolCalls, agentCalls, skillCalls };
}

function readTailLines(filePath, fileSize, maxBytes) {
  const startOffset = Math.max(0, fileSize - maxBytes);
  const bytesToRead = fileSize - startOffset;
  const fd = openSync(filePath, "r");
  const buffer = Buffer.alloc(bytesToRead);
  try { readSync(fd, buffer, 0, bytesToRead, startOffset); }
  finally { closeSync(fd); }
  const lines = buffer.toString("utf8").split("\n");
  if (startOffset > 0 && lines.length > 0) lines.shift();
  return lines;
}

async function readAllLines(filePath) {
  const lines = [];
  const rl = createInterface({ input: createReadStream(filePath), crlfDelay: Infinity });
  for await (const line of rl) lines.push(line);
  return lines;
}

async function main() {
  let data = {};
  try {
    const chunks = [];
    for await (const chunk of process.stdin) chunks.push(chunk);
    data = JSON.parse(Buffer.concat(chunks).toString());
  } catch { /* no stdin data */ }

  const cwd = data.cwd || process.cwd();
  const folder = basename(cwd);

  // git branch
  let branch = "";
  try {
    branch = execSync("git branch --show-current 2>/dev/null", {
      cwd, encoding: "utf-8", timeout: 3000,
    }).trim();
    // uncommitted changes?
    try {
      execSync("git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null", { cwd, timeout: 3000 });
    } catch { branch += "?"; }
  } catch { /* not a git repo */ }

  // context bar
  const ctxPct = data?.context_window?.used_percentage;
  const ctxSize = data?.context_window?.context_window_size || 200000;
  const maxK = Math.round(ctxSize / 1000);
  let ctxBar = "";
  if (ctxPct != null) {
    ctxBar = renderContextBar(Math.round(ctxPct), maxK);
  }

  // call counts
  const { toolCalls, agentCalls, skillCalls } = await countCalls(data.transcript_path);
  const countParts = [];
  if (toolCalls > 0) countParts.push(`\uD83D\uDD27${toolCalls}`);
  if (agentCalls > 0) countParts.push(`\uD83E\uDD16${agentCalls}`);
  if (skillCalls > 0) countParts.push(`\u26A1${skillCalls}`);
  const countStr = countParts.join(" ");

  // CWM plan status
  const planStatus = getPlanStatus(cwd);

  // 5h rate limit
  const fiveHour = data?.rate_limits?.five_hour;
  let fiveHourStr = "";
  if (fiveHour?.used_percentage != null) {
    const pct = Math.round(fiveHour.used_percentage);
    const barWidth = 3;
    const step = 90 / (barWidth * 2);
    let bar5h = "";
    for (let i = 0; i < barWidth; i++) {
      const halfAt = (i * 2 + 1) * step;
      const fullAt = (i * 2 + 2) * step;
      if (pct >= fullAt) {
        bar5h += `${C_YELLOW}\u2588${C_RESET}`;
      } else if (pct >= halfAt) {
        bar5h += `${C_YELLOW}\u2584${C_RESET}`;
      } else {
        bar5h += `${C_BAR_EMPTY}\u2591${C_RESET}`;
      }
    }
    let timeLabel = "5h";
    const resetAt = fiveHour.resets_at || fiveHour.reset_at || fiveHour.reset;
    if (resetAt) {
      const resetMs = resetAt < 1e12 ? resetAt * 1000 : resetAt;
      const remainMs = Math.max(0, resetMs - Date.now());
      const h = Math.floor(remainMs / 3600000);
      const m = Math.floor((remainMs % 3600000) / 60000);
      timeLabel = h > 0 ? `${h}h${String(m).padStart(2, "0")}m` : `${m}m`;
    }
    fiveHourStr = `${bar5h} ${C_GRAY}${timeLabel}:${pct}%${C_RESET}`;
  }

  // build output
  const parts = [];
  const loc = branch
    ? `\uD83D\uDCC2 ${C_ACCENT}${folder}${C_RESET} | \uD83D\uDD00 ${C_YELLOW}${branch}${C_RESET}`
    : `\uD83D\uDCC2 ${C_ACCENT}${folder}${C_RESET}`;
  parts.push(loc);
  if (ctxBar) parts.push(ctxBar);
  if (countStr) parts.push(countStr);
  if (planStatus) parts.push(planStatus);
  if (fiveHourStr) parts.push(fiveHourStr);

  console.log(parts.join(" | "));
}

main();
