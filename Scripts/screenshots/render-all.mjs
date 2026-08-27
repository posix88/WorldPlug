#!/usr/bin/env node
// Batch-renders every shot in captions.json, for every device it has a raw capture for, in every
// locale it has a caption for — into out/<locale>/<shot-id>.png. Single browser instance reused
// across all renders (faster than spawning one per image, and this can be dozens of images).
//
// Usage: node render-all.mjs
// Wired into: bundle exec fastlane screenshots

import fs from "node:fs";
import path from "node:path";
import puppeteer from "puppeteer";
import { __dirname, executablePath, renderScreenshot } from "./lib.mjs";

const manifestPath = path.join(__dirname, "captions.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf-8"));

const rawDir = path.join(__dirname, "raw");
const outDir = path.join(__dirname, "out");

let rendered = 0;
let skipped = 0;
let usedNonEnglishRawForNonEnglishLocale = false;

const browser = await puppeteer.launch({ executablePath });
try {
  const page = await browser.newPage();

  for (const shot of manifest.shots) {
    for (const [deviceName, rawFile] of Object.entries(shot.raw)) {
      const device = manifest.devices[deviceName];
      if (!device) {
        console.warn(`Skipping ${shot.id}/${deviceName}: no "${deviceName}" entry in devices.`);
        skipped++;
        continue;
      }

      const inputPath = path.join(rawDir, rawFile);
      if (!fs.existsSync(inputPath)) {
        console.warn(`Skipping ${shot.id}/${deviceName}: raw/${rawFile} not found.`);
        skipped++;
        continue;
      }

      for (const [locale, caption] of Object.entries(shot.captions)) {
        if (locale !== "en-US") {
          // We only track one raw capture per device per shot (no separate per-locale raw
          // captures yet), so a non-English caption is composited over whatever screenshot we
          // have — almost certainly still showing English UI text underneath. Fine as a
          // placeholder; swap in a real localized capture for this shot/device once you have one.
          usedNonEnglishRawForNonEnglishLocale = true;
        }

        const localeDir = path.join(outDir, locale);
        fs.mkdirSync(localeDir, { recursive: true });
        const outputPath = path.join(localeDir, `${shot.id}.png`);

        await renderScreenshot(page, {
          input: inputPath,
          caption,
          output: outputPath,
          width: device.width,
          height: device.height,
        });
        console.log(`Wrote ${path.relative(__dirname, outputPath)}`);
        rendered++;
      }
    }
  }
} finally {
  await browser.close();
}

console.log(`\n${rendered} rendered, ${skipped} skipped.`);
if (usedNonEnglishRawForNonEnglishLocale) {
  console.log(
    "Note: non-English locales were rendered from the same raw capture as en-US (no separate " +
      "localized raw screenshot exists yet) — the caption is localized but the app UI in the " +
      "screenshot itself is still in English. Capture a real localized raw screenshot and add " +
      "it to captions.json's \"raw\" entry when you have one."
  );
}
