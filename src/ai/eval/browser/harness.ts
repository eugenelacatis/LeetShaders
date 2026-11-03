// Browser half of the eval harness. Loaded by run.ts through Vite inside
// headless Chromium (SwiftShader WebGL2). It drives the production judge
// (src/judge/combiner.ts) on the one shared pipeline. The LLM stage is
// bridged back to Node via window.nodeJudge, so the API key never enters
// the page.

import { judge } from '../../../judge/combiner';
import { compileAndRender, CANVAS_SIZE } from '../../../judge/pipeline';
import { sampleUniforms } from '../../../judge/uniforms';
import { rgbaToPngBase64 } from '../../imageEncode';
import type { HarnessWindow } from '../harnessTypes';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-empty-object-type
  interface Window extends HarnessWindow {}
}

async function renderPng(src: string): Promise<string | null> {
  const r = compileAndRender(src);
  if ('type' in r) return null;
  return rgbaToPngBase64(r.pixels, CANVAS_SIZE, CANVAS_SIZE);
}

window.runJudge = async ({ shaderSrc, challenge, uniformSeed }) => {
  const result = await judge(
    shaderSrc,
    challenge,
    async (input) => {
      const [userPngBase64, referencePngBase64] = await Promise.all([
        rgbaToPngBase64(input.userRender, CANVAS_SIZE, CANVAS_SIZE),
        rgbaToPngBase64(input.referenceRender, CANVAS_SIZE, CANVAS_SIZE),
      ]);
      return window.nodeJudge({
        challenge: input.challenge,
        userShaderSrc: input.userShaderSrc,
        userPngBase64,
        referencePngBase64,
      });
    },
    undefined,
    sampleUniforms(uniformSeed),
  );
  return {
    result,
    userPngBase64: await renderPng(shaderSrc),
    referencePngBase64: await renderPng(challenge.referenceShaderSrc),
  };
};

// RGB (0-255) at the centers of an n x n grid, row-major from the bottom-left
// (GL order). Used by gen/adversarial.ts to bake color-table cheats.
window.renderGrid = (src, n) => {
  const r = compileAndRender(src);
  if ('type' in r) return null;
  const out: number[] = [];
  const cell = CANVAS_SIZE / n;
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      const px = Math.floor((x + 0.5) * cell);
      const py = Math.floor((y + 0.5) * cell);
      const i = (py * CANVAS_SIZE + px) * 4;
      out.push(r.pixels[i] ?? 0, r.pixels[i + 1] ?? 0, r.pixels[i + 2] ?? 0);
    }
  }
  return out;
};

window.harnessReady = true;
document.getElementById('status')!.textContent = 'ready';
