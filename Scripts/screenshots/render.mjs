#!/usr/bin/env node
// Composites a single raw device screenshot + a caption into a finished, on-brand App Store
// screenshot. For rendering everything in captions.json at once, use render-all.mjs instead
// (also wired into `bundle exec fastlane screenshots`).
//
// Usage:
//   node render.mjs --input raw/countries.png --caption "200+ countries, one glance" \
//     --output out/en-US/01_countries.png --width 1320 --height 2868
//
// Optional:
//   --eyebrow "Socket Buddy"    small label above the caption (defaults to "Socket Buddy")
//   --caption-size 92           caption font size in px, tune per caption length
//   --shot-top 34               where the screenshot starts, as % of canvas height

import puppeteer from "puppeteer";
import { executablePath, renderScreenshot } from "./lib.mjs";

function parseArgs(argv) {
  const args = {};
  for (let i = 0; i < argv.length; i += 2) {
    const key = argv[i].replace(/^--/, "");
    args[key] = argv[i + 1];
  }
  return args;
}

const args = parseArgs(process.argv.slice(2));

const required = ["input", "caption", "output", "width", "height"];
for (const key of required) {
  if (!args[key]) {
    console.error(`Missing required --${key}`);
    process.exit(1);
  }
}

const browser = await puppeteer.launch({ executablePath });
try {
  const page = await browser.newPage();
  const outputPath = await renderScreenshot(page, {
    input: args.input,
    caption: args.caption,
    output: args.output,
    width: parseInt(args.width, 10),
    height: parseInt(args.height, 10),
    eyebrow: args.eyebrow,
    captionSize: args["caption-size"] ? parseInt(args["caption-size"], 10) : undefined,
    shotTop: args["shot-top"] ? `${args["shot-top"]}%` : undefined,
  });
  console.log(`Wrote ${outputPath}`);
} finally {
  await browser.close();
}
