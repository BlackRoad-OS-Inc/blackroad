import fs from 'fs';
import path from 'path';

async function postToSlack(webhookUrl, text) {
  const response = await fetch(webhookUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text }),
  });
  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Slack webhook failed: ${response.status} ${body}`);
  }
}

function extractScorecard(markdown) {
  const lines = markdown.split(/\r?\n/);
  const startIndex = lines.findIndex((line) => line.trim().startsWith('| KPI'));
  if (startIndex === -1) return markdown.slice(0, 300);
  const slice = [];
  for (let i = startIndex; i < lines.length; i += 1) {
    const line = lines[i];
    if (!line.trim()) break;
    slice.push(line);
  }
  return slice.join('\n');
}

function buildMessage(title, scorecard) {
  return `*${title}*\n${scorecard}`;
}

async function main(argv) {
  const [pulsePath, webhookUrl] = argv;
  if (!pulsePath || !webhookUrl) {
    console.error('Usage: node slack.js <pulse.md> <webhook-url>');
    process.exit(1);
  }

  const markdown = fs.readFileSync(path.resolve(pulsePath), 'utf-8');
  const title = `System Performance Pulse (${new Date().toISOString().split('T')[0]})`;
  const scorecard = extractScorecard(markdown);
  const message = buildMessage(title, scorecard);
  await postToSlack(webhookUrl, message);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main(process.argv.slice(2)).catch((error) => {
    console.error(error.message);
    process.exit(1);
  });
}
// tools/pulse/slack.js
// Usage: node tools/pulse/slack.js pulses/SYS-PERF-YYYY-WW.md "$SLACK_WEBHOOK_URL"
import fs from "node:fs";

const file = process.argv[2];
const url = process.argv[3];
if (!file || !url) {
  console.error("Usage: node tools/pulse/slack.js <pulse.md> <SLACK_WEBHOOK_URL>");
  process.exit(2);
}
const text = fs.readFileSync(file, "utf8").slice(0, 3000); // Slack limit-ish
const payload = { text: `*${file}*\n${text}` };

const res = await fetch(url, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify(payload)
});
if (!res.ok) {
  console.error("Slack post failed:", res.status, await res.text());
  process.exit(1);
}
console.log("Posted to Slack:", file);
