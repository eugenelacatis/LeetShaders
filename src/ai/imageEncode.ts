// AI Systems & Integration. Encode raw RGBA Uint8Array buffers (the
// shape returned by the WebGL2 pipeline's `readPixels`) to base64 PNG
// strings for the Anthropic vision API.
//
// Browser-only. The eval harness under src/ai/eval/ runs in node and
// will need its own encoder (see AI_SYSTEMS.md task 2); add it there
// when wiring the harness, do not pollute this module with a node
// branch that tsconfig.app.json cannot type-check.

export async function rgbaToPngBase64(
  rgba: Uint8Array,
  width: number,
  height: number,
): Promise<string> {
  const expected = width * height * 4;
  if (rgba.length !== expected) {
    throw new Error(
      `rgbaToPngBase64: buffer length ${rgba.length} does not match ${width}x${height}x4 (${expected})`,
    );
  }

  const blob = await renderToPngBlob(rgba, width, height);
  const arrayBuffer = await blob.arrayBuffer();
  return arrayBufferToBase64(arrayBuffer);
}

/**
 * readPixels returns rows bottom-up (GL origin is the bottom-left); images
 * are stored top-down. Reverse the row order so the PNG shows the render
 * the right way up. Pure, exported for tests.
 */
export function flipRowsToTopDown(rgba: Uint8Array, width: number, height: number): Uint8ClampedArray<ArrayBuffer> {
  const rowBytes = width * 4;
  const out = new Uint8ClampedArray(new ArrayBuffer(rgba.length));
  for (let y = 0; y < height; y++) {
    const src = (height - 1 - y) * rowBytes;
    out.set(rgba.subarray(src, src + rowBytes), y * rowBytes);
  }
  return out;
}

async function renderToPngBlob(
  rgba: Uint8Array,
  width: number,
  height: number,
): Promise<Blob> {
  // The flip copies into a fresh ArrayBuffer-backed view, which also
  // satisfies ImageData's constructor type (the source buffer may be
  // SharedArrayBuffer-backed under TS 5.7).
  const imageData = new ImageData(flipRowsToTopDown(rgba, width, height), width, height);

  if (typeof OffscreenCanvas !== 'undefined') {
    const canvas = new OffscreenCanvas(width, height);
    const ctx = canvas.getContext('2d');
    if (!ctx) {
      throw new Error('rgbaToPngBase64: OffscreenCanvas 2d context unavailable');
    }
    ctx.putImageData(imageData, 0, 0);
    return canvas.convertToBlob({ type: 'image/png' });
  }

  // Fallback for browsers without OffscreenCanvas. Tests using jsdom
  // hit this path; jsdom's canvas backend may need a polyfill.
  const canvas = document.createElement('canvas');
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext('2d');
  if (!ctx) {
    throw new Error('rgbaToPngBase64: HTMLCanvasElement 2d context unavailable');
  }
  ctx.putImageData(imageData, 0, 0);
  return new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (blob) => (blob ? resolve(blob) : reject(new Error('canvas.toBlob returned null'))),
      'image/png',
    );
  });
}

function arrayBufferToBase64(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer);
  // 32 KiB chunks keep us well under the spread-arg limit while staying
  // fast for our 512x512 fixed render size.
  const chunkSize = 0x8000;
  let binary = '';
  for (let offset = 0; offset < bytes.length; offset += chunkSize) {
    const chunk = bytes.subarray(offset, offset + chunkSize);
    binary += String.fromCharCode(...chunk);
  }
  return btoa(binary);
}
