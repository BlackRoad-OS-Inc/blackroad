#!/usr/bin/env node
/**
 * Model miner power cost and “near-zero” via duty cycle + solar offset.
 * Usage:
 *   node tools/power-report.mjs --watts=5 --kwh=0.15 --on=15 --period=60 --solarWhDay=30 --revDay=0
 * - watts: power while running
 * - kwh: price per kWh
 * - on: minutes on per period
 * - period: minutes in the full cycle (default 60)
 * - solarWhDay: daily Wh from panel/battery (optional)
 * - revDay: assumed revenue/day USD (0 default)
 */
const args = Object.fromEntries(process.argv.slice(2).map(x => x.split('=').map(s => s.replace(/^--/, ''))));
const watts = +args.watts || 5;
const kwh = +args.kwh || 0.15;
const on = +args.on || 15;
const period = +args.period || 60;
const solarWhDay = +args.solarWhDay || 0;
const revDay = +args.revDay || 0;

const duty = Math.min(Math.max(on / period, 0), 1);
const avgW = watts * duty;
const kwhDay = (avgW / 1000) * 24;
const costDay = kwhDay * kwh;
const costMonth = costDay * 30;
const gridWhDay = Math.max(avgW * 24 - solarWhDay, 0);
const gridCostMonth = (gridWhDay / 1000) * kwh * 30;
const marginDay = revDay - costDay;
const marginMonth = revDay * 30 - costMonth;

console.log(JSON.stringify({
  watts,
  duty,
  avgW,
  kwh,
  kwhDay,
  costDay,
  costMonth,
  solarWhDay,
  gridWhDay,
  gridCostMonth,
  revDay,
  marginDay,
  marginMonth
}, null, 2));

/*
Examples:

// Pi xmrig "15 on / 45 off", 5W while on, $0.15/kWh, 30 Wh/day solar offset
node tools/power-report.mjs --watts=5 --kwh=0.15 --on=15 --period=60 --solarWhDay=30
*/
