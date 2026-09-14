// Shared rendering core used by both render.mjs (single image, CLI) and render-all.mjs (batch,
// driven by captions.json) — keeps the actual Puppeteer/template-filling logic in one place.

import path from "node:path";
import fs from "node:fs";
import os from "node:os";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

export const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const templatePath = path.join(__dirname, "template.html");

// Puppeteer's own bundled Chromium download failed behind this network's TLS proxy — point it
// at the system Google Chrome install instead. Override with PUPPETEER_EXECUTABLE_PATH if yours
// lives elsewhere.
export const executablePath =
  process.env.PUPPETEER_EXECUTABLE_PATH ?? "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome";

/**
 * Upscales an image to the specified dimensions if needed, returning either the original path
 * (if already at the correct size) or a temp file path with the upscaled version.
 * @param {string} inputPath
 * @param {number} targetWidth
 * @param {number} targetHeight
 * @returns {Promise<{path: string, isTempFile: boolean}>}
 */
export async function ensureImageSize(inputPath, targetWidth, targetHeight) {
  const metadata = await sharp(inputPath).metadata();
  const { width, height } = metadata;

  // If already at target size or larger, return as-is
  if (width >= targetWidth && height >= targetHeight) {
    return { path: inputPath, isTempFile: false };
  }

  // Upscale to target dimensions
  const tempFile = path.join(os.tmpdir(), `upscaled-${Date.now()}-${path.basename(inputPath)}`);
  await sharp(inputPath)
    .resize(targetWidth, targetHeight, {
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .toFile(tempFile);

  return { path: tempFile, isTempFile: true };
}

/**
 * Renders one captioned screenshot on an existing Puppeteer page.
 * @param {import("puppeteer").Page} page
 * @param {{input: string, caption: string, output: string, width: number, height: number,
 *   eyebrow?: string, captionSize?: number, shotTop?: string}} options
 */
export async function renderScreenshot(page, options) {
  const {
    input,
    caption,
    output,
    width,
    height,
    eyebrow = "Socket Buddy",
    captionSize = Math.round(width * 0.07),
    shotTop = "21%",
  } = options;

  const inputPath = path.resolve(input);
  const outputPath = path.resolve(output);

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
      shotTop: typeof shotTop === "number" ? `${shotTop}%` : shotTop,
      eyebrow,
      caption,
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
  return outputPath;
}
