// Regenerates every eval fixture from src/challenges/ + specs.ts.
//
//   npx tsx src/ai/eval/gen/generate.ts
//
// Writes fixtures/challenges/<slug>.{glsl,json} and 10 fixtures per
// (challenge, category). Color-table cheats need real renders, so this opens
// the browser harness once. Output is deterministic; commit the result.

import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { openHarness } from '../browserSession';
import type { HarnessWindow } from '../harnessTypes';
import { FIXTURES_DIR, VERDICTS } from '../fixtures';
import { INJECTIONS, SPECS, type Edit } from './specs';

const REPO = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..', '..');
const CHALLENGES_SRC = join(REPO, 'src', 'challenges');

// ─── Source transforms ────────────────────────────────────────────────────────

export function applyEdits(src: string, edit: Edit): string {
  let out = src;
  for (const [find, replace] of edit.edits) {
    if (!out.includes(find)) throw new Error(`edit "${edit.label}": "${find}" not found`);
    out = out.replace(find, replace);
  }
  return out;
}

function stripComments(src: string): string {
  return src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/[ \t]*\/\/.*$/gm, '')
    .replace(/\n{3,}/g, '\n\n');
}

function rename(src: string, map: Record<string, string>): string {
  let out = src;
  for (const [from, to] of Object.entries(map)) {
    out = out.replace(new RegExp(`\\b${from}\\b`, 'g'), to);
  }
  return out;
}

/** Move main's body into a helper and call it, optionally with a clamp. */
function wrapHelper(src: string, clampOutput = false): string {
  if (!src.includes('void main()')) throw new Error('no main()');
  const body = clampOutput ? '  shade();\n  fragColor = clamp(fragColor, 0.0, 1.0);' : '  shade();';
  return `${src.replace('void main()', 'void shade()')}\nvoid main() {\n${body}\n}\n`;
}

function reindent(src: string): string {
  return src
    .split('\n')
    .map((l) => l.replace(/^( {4})+/, (m) => '  '.repeat(m.length / 4)).trimEnd())
    .join('\n');
}

function ensureUniform(src: string, decl: string): string {
  if (src.includes(decl)) return src;
  return src.replace('precision highp float;', `precision highp float;\n${decl}`);
}

function inject(src: string, payload: string): string {
  return src.replace('void main()', `${payload}\nvoid main()`);
}

/** Matches the reference only at the default inputs; wrong everywhere else. */
function timeBranch(ref: string, kind: 'time-eq' | 'mouse-eq' | 'time-gt'): string {
  let src = wrapHelper(ref);
  src = ensureUniform(src, 'uniform float u_time;');
  src = ensureUniform(src, 'uniform vec2 u_mouse;');
  const tail = {
    'time-eq': '  if (u_time != 0.0) fragColor = vec4(1.0 - fragColor.rgb, 1.0);',
    'mouse-eq': '  if (u_mouse != vec2(0.0)) fragColor = vec4(0.0, 0.0, 0.0, 1.0);',
    'time-gt': '  if (u_time > 0.0001) fragColor = vec4(fragColor.bgr * 0.5, 1.0);',
  }[kind];
  return src.replace('  shade();\n}', `  shade();\n${tail}\n}`);
}

function colorTable(grid: number[], n: number): string {
  const entries: string[] = [];
  for (let i = 0; i < n * n; i++) {
    const [r, g, b] = [grid[i * 3]!, grid[i * 3 + 1]!, grid[i * 3 + 2]!].map((v) =>
      (v / 255).toFixed(3),
    );
    entries.push(`vec3(${r}, ${g}, ${b})`);
  }
  const rows: string[] = [];
  for (let i = 0; i < entries.length; i += 4) rows.push('  ' + entries.slice(i, i + 4).join(', '));
  return `#version 300 es
precision highp float;

uniform vec2 u_resolution;
out vec4 fragColor;

// Precomputed palette, ${n}x${n}, row-major from the bottom-left.
const vec3 PALETTE[${n * n}] = vec3[${n * n}](
${rows.join(',\n')}
);

void main() {
  ivec2 cell = ivec2(gl_FragCoord.xy / u_resolution * ${n}.0);
  fragColor = vec4(PALETTE[cell.y * ${n} + cell.x], 1.0);
}
`;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function clearGenerated(): Promise<void> {
  for (const dir of ['challenges', ...VERDICTS]) {
    const path = join(FIXTURES_DIR, dir);
    await mkdir(path, { recursive: true });
    for (const f of await readdir(path)) {
      if (f.endsWith('.glsl') || f.endsWith('.json') || f.endsWith('.png')) await rm(join(path, f));
    }
  }
}

async function main(): Promise<void> {
  await clearGenerated();
  const refs = new Map<string, string>();
  for (const spec of SPECS) {
    refs.set(spec.slug, await readFile(join(CHALLENGES_SRC, `${spec.slug}.glsl`), 'utf8'));
  }

  const files = new Map<string, string>(); // relative path -> source
  const put = (verdict: string, slug: string, label: string, src: string): void => {
    const key = `${verdict}/${slug}-${label}.glsl`;
    if (files.has(key)) throw new Error(`duplicate fixture ${key}`);
    files.set(key, src.endsWith('\n') ? src : `${src}\n`);
  };

  const session = await openHarness();
  try {
    for (const spec of SPECS) {
      const ref = refs.get(spec.slug)!;
      const meta = JSON.parse(
        await readFile(join(CHALLENGES_SRC, `${spec.slug}.json`), 'utf8'),
      ) as Record<string, unknown>;
      await writeFile(join(FIXTURES_DIR, 'challenges', `${spec.slug}.glsl`), ref);
      await writeFile(
        join(FIXTURES_DIR, 'challenges', `${spec.slug}.json`),
        JSON.stringify(
          {
            id: spec.slug,
            slug: spec.slug,
            title: meta.title,
            description: meta.description,
            difficulty: meta.difficulty,
            tolerance: meta.tolerance,
            useBlur: meta.useBlur,
          },
          null,
          2,
        ) + '\n',
      );

      // correct: 6 mechanical rewrites + 4 hand-written implementations
      put('correct', spec.slug, 'gen-strip-comments', stripComments(ref));
      put('correct', spec.slug, 'gen-rename', rename(ref, spec.renames));
      put('correct', spec.slug, 'gen-helper', wrapHelper(ref));
      put('correct', spec.slug, 'gen-rename-helper', wrapHelper(rename(ref, spec.renames)));
      put(
        'correct',
        spec.slug,
        'gen-rename-strip-clamp',
        wrapHelper(rename(stripComments(ref), spec.renames), true),
      );
      put('correct', spec.slug, 'gen-reindent-helper', reindent(wrapHelper(stripComments(ref))));
      for (const h of spec.handCorrect) put('correct', spec.slug, `hand-${h.label}`, h.src);

      // almost-correct
      for (const e of spec.almost) put('almost-correct', spec.slug, e.label, applyEdits(ref, e));

      // wrong: 6 edits + the other 4 references
      for (const e of spec.wrong) put('wrong', spec.slug, e.label, applyEdits(ref, e));
      for (const other of SPECS) {
        if (other.slug !== spec.slug)
          put('wrong', spec.slug, `other-${other.slug}`, refs.get(other.slug)!);
      }

      // adversarial: 3 color tables, 3 default-input branches, 4 injections
      for (const n of [8, 16, 24]) {
        const grid = await session.page.evaluate(
          ([src, size]) => (globalThis as unknown as HarnessWindow).renderGrid(src, size),
          [ref, n] as const,
        );
        if (!grid) throw new Error(`reference ${spec.slug} failed to render`);
        put('adversarial', spec.slug, `table-${n}`, colorTable(grid, n));
      }
      for (const kind of ['time-eq', 'mouse-eq', 'time-gt'] as const) {
        put('adversarial', spec.slug, kind, timeBranch(ref, kind));
      }
      const injected = [...spec.injectMild, ...spec.injectBorderline];
      injected.forEach((e, i) =>
        put('adversarial', spec.slug, e.label, inject(applyEdits(ref, e), INJECTIONS[i]!)),
      );
    }
  } finally {
    await session.close();
  }

  for (const [rel, src] of files) await writeFile(join(FIXTURES_DIR, rel), src);
  for (const v of VERDICTS) {
    console.log(`${v}: ${[...files.keys()].filter((k) => k.startsWith(`${v}/`)).length}`);
  }
  console.log(`Wrote ${files.size} fixtures for ${SPECS.length} challenges.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
