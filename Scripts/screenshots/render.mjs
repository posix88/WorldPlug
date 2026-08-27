#!/usr/bin/env node
// Composites a raw device screenshot + a caption into a finished, on-brand App Store
// screenshot, using Socket Buddy's own colors (see template.html). Renders via headless Chrome
// (Puppeteer) so the output is a pixel-perfect PNG at the exact target dimensions — no manual
// screenshotting of a browser tab.
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
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

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

const width = parseInt(args.width, 10);
const height = parseInt(args.height, 10);
const eyebrow = args.eyebrow ?? "Socket Buddy";
const captionSize = args["caption-size"] ? parseInt(args["caption-size"], 10) : Math.round(width * 0.07);
const shotTop = args["shot-top"] ? `${args["shot-top"]}%` : "21%";

const inputPath = path.resolve(args.input);
const outputPath = path.resolve(args.output);
const templatePath = path.join(__dirname, "template.html");

// Puppeteer's own bundled Chromium download failed behind this network's TLS proxy — point it
// at the system Google Chrome install instead. Override with PUPPETEER_EXECUTABLE_PATH if yours
// lives elsewhere.
const executablePath =
  process.env.PUPPETEER_EXECUTABLE_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

const browser = await puppeteer.launch({ executablePath });
try {
  const page = await browser.newPage();
  await page.setViewport({ width, height, deviceScaleFactor: 1 });
  await page.goto(`file://${templatePath}`, { waitUntil: "load" });

  await page.evaluate(
    (config) => {
      const root = document.documentElement.style;
      root.setProperty("--canvas-w", `${config.width}px`);
      root.setProperty("--canvas-h", `${config.height}px`);
      root.setProperty("--caption-size", `${config.captionSize}px`);
      root.setProperty("--shot-top", config.shotTop);

      document.getElementById("eyebrow").textContent = config.eyebrow;
      document.getElementById("caption").textContent = config.caption;
      document.getElementById("screenshot").src = config.imagePath;
    },
    {
      width,
      height,
      captionSize,
      shotTop,
      eyebrow,
      caption: args.caption,
      imagePath: `file://${inputPath}`,
    }
  );

  // Let the image finish decoding before screenshotting.
  await page.evaluate(async () => {
    const img = document.getElementById("screenshot");
    if (!img.complete) {
      await new Promise((resolve) => {
        img.onload = resolve;
        img.onerror = resolve;
      });
    }
  });

  await page.screenshot({ path: outputPath, type: "png" });
  console.log(`Wrote ${outputPath}`);
} finally {
  await browser.close();
}
