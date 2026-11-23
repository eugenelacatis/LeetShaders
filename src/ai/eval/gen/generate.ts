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
import { INJECTIONS, SPECS, type Edit, type WrongTransform } from './specs';

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

/** An animated reference frozen at t = 0: `u_time` dropped and every use replaced by 0.0. */
function staticFrame(ref: string): string {
  if (!ref.includes('uniform float u_time;\n')) throw new Error('static-frame: no u_time uniform');
  return ref.replace('uniform float u_time;\n', '').replace(/\bu_time\b/g, '0.0');
}

/** Whole-image wrong answers: a color post-process or a remap of gl_FragCoord. */
function wrongTransform(ref: string, kind: WrongTransform): string {
  if (kind === 'inverted' || kind === 'bgr') {
    const tail = kind === 'inverted' ? 'fragColor.rgb = 1.0 - fragColor.rgb;' : 'fragColor.rgb = fragColor.bgr;';
    return wrapHelper(ref).replace('  shade();\n}', `  shade();\n  ${tail}\n}`);
  }
  if (!ref.includes('gl_FragCoord.xy')) throw new Error(`${kind}: no gl_FragCoord.xy`);
  const coord = {
    'flip-y': 'vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y)',
    'mirror-x': 'vec2(u_resolution.x - gl_FragCoord.x, gl_FragCoord.y)',
    zoom: '(gl_FragCoord.xy * 2.0 - u_resolution.xy * 0.5)',
  }[kind];
  return ref.replaceAll('gl_FragCoord.xy', coord);
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
  const started = performance.now();
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
            track: meta.track,
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
        rename(wrapHelper(stripComments(ref), true), spec.renames),
      );
      put('correct', spec.slug, 'gen-reindent-helper', reindent(wrapHelper(stripComments(ref))));
      for (const h of spec.handCorrect) put('correct', spec.slug, `hand-${h.label}`, h.src);

      // almost-correct
      for (const e of spec.almost) put('almost-correct', spec.slug, e.label, applyEdits(ref, e));

      // wrong: edits, hand-written sources, whole-image transforms and other references
      for (const e of spec.wrong) put('wrong', spec.slug, e.label, applyEdits(ref, e));
      for (const h of spec.handWrong ?? []) put('wrong', spec.slug, h.label, h.src);
      for (const kind of spec.genWrong ?? []) put('wrong', spec.slug, `gen-${kind}`, wrongTransform(ref, kind));
      for (const other of spec.others) {
        const otherSrc = refs.get(other);
        if (!otherSrc) throw new Error(`${spec.slug}: unknown other challenge ${other}`);
        put('wrong', spec.slug, `other-${other}`, otherSrc);
      }

      // adversarial: color tables, 3 default-input branches, injections (10 total)
      for (const n of spec.tables ?? [8, 16, 24]) {
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
      if (spec.staticFrame) put('adversarial', spec.slug, 'static-frame', staticFrame(ref));
      for (const h of spec.handAdversarial ?? []) put('adversarial', spec.slug, h.label, h.src);
      const injected = [...spec.injectMild, ...spec.injectBorderline];
      injected.forEach((e, i) => {
        const payload = INJECTIONS[i];
        if (!payload) throw new Error(`${spec.slug}: only ${INJECTIONS.length} injection payloads`);
        put('adversarial', spec.slug, e.label, inject(applyEdits(ref, e), payload));
      });
    }
  } finally {
    await session.close();
  }

  for (const spec of SPECS) {
    for (const v of VERDICTS) {
      const n = [...files.keys()].filter((k) => k.startsWith(`${v}/${spec.slug}-`)).length;
      if (n !== 10) throw new Error(`${spec.slug}/${v}: ${n} fixtures, expected 10`);
    }
  }

  for (const [rel, src] of files) await writeFile(join(FIXTURES_DIR, rel), src);
  for (const v of VERDICTS) {
    console.log(`${v}: ${[...files.keys()].filter((k) => k.startsWith(`${v}/`)).length}`);
  }
  console.log(
    `Wrote ${files.size} fixtures for ${SPECS.length} challenges in ${((performance.now() - started) / 1000).toFixed(1)}s.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
