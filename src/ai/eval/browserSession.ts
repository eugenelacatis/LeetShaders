// Starts Vite and headless Chromium and opens the eval harness page.
// Shared by run.ts and the fixture generators in gen/.

import { createServer, type ViteDevServer } from 'vite';
import { chromium, type Browser, type Page } from '@playwright/test';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');

export interface HarnessSession {
  page: Page;
  close: () => Promise<void>;
}

export async function openHarness(
  beforeLoad?: (page: Page) => Promise<void>,
): Promise<HarnessSession> {
  const server: ViteDevServer = await createServer({
    root: REPO_ROOT,
    configFile: join(REPO_ROOT, 'vite.config.ts'),
    logLevel: 'error',
    server: { port: 0, strictPort: false },
  });
  await server.listen();
  const base = server.resolvedUrls?.local[0];
  if (!base) throw new Error('vite did not report a local URL');

  // SwiftShader gives deterministic WebGL2 in headless mode, independent of
  // the host GPU, so MAE numbers are reproducible across machines.
  const browser: Browser = await chromium.launch({
    args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'],
  });
  const page = await browser.newPage();
  page.on('pageerror', (err) => console.error('[harness page error]', err.message));
  if (beforeLoad) await beforeLoad(page);
  await page.goto(new URL('src/ai/eval/browser/harness.html', base).toString());
  await page.waitForFunction('window.harnessReady === true', undefined, { timeout: 60_000 });

  return {
    page,
    close: async () => {
      await browser.close();
      await server.close();
    },
  };
}
