// Judge eval harness. Runs the production two-stage judge (MAE bands, then
// the Claude vision judge) on every fixture, in headless Chromium, through
// the shared WebGL2 pipeline. See CALIBRATION.md.
//
// Usage:
//   npx tsx src/ai/eval/run.ts                    # dry run: fixture counts only
//   npx tsx src/ai/eval/run.ts --mae-only         # free: MAE + band routing, no API calls
//   npx tsx src/ai/eval/run.ts --live             # full judge; writes REPORT.md
//
// Options:
//   --set=tuning|heldout|all   which split to run (default: all)
//   --repeat=N                 live only: run the set N times to measure verdict spread
//   --max-cost=USD             live only: abort when spend passes this (default 5)
//   --seed=N                   uniform sampling seed (default 1337)
//   --yes                      live only: skip the cost confirmation pause
//   --report=FILE              live only: report filename in this folder (default REPORT.md)

import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execSync } from 'node:child_process';
import * as dotenv from 'dotenv';
import type { Challenge, CheatCheckOutput, JudgeResult, LLMJudgeOutput } from '../../judge/types';
import { DEFAULT_BANDS, classifyByBand } from '../bandLogic';
import { toCheatCheckOutput, toLLMJudgeOutput } from '../judgeRequest';
import { CHEAT_CHECK_MODEL, JUDGE_MODEL } from '../models';
import { cheatCheckFromSource, judgeFromPngs } from './judgeCall';
import { openHarness } from './browserSession';
import type {
  HarnessWindow,
  NodeCheatCheckArgs,
  NodeJudgeArgs,
  RunJudgeArgs,
  RunJudgeOutput,
} from './harnessTypes';
import { FIXTURES_DIR, VERDICTS, loadChallenges, discoverFixtures, type Fixture, type Verdict } from './fixtures';

// ANTHROPIC_API_KEY may live in .env.local (gitignored), same as seed.ts.
dotenv.config({ path: '.env.local' });
dotenv.config();

const HERE = dirname(fileURLToPath(import.meta.url));
const OUT_DIR = join(HERE, 'out');
const REPORT_PATH = join(HERE, 'REPORT.md');
const SPLIT_PATH = join(FIXTURES_DIR, 'split.json');

// List prices, USD per million tokens (Anthropic pricing, checked
// 2026-11-02). Cache writes bill at 1.25x input.
interface Price {
  input: number;
  output: number;
  cacheWrite: number;
  cacheRead: number;
}
const PRICES: Record<string, Price> = {
  [JUDGE_MODEL]: { input: 4, output: 20, cacheWrite: 5, cacheRead: 0.2 },
  [CHEAT_CHECK_MODEL]: { input: 0.1, output: 0.5, cacheWrite: 0.125, cacheRead: 0.01 },
};
// Rough pre-flight estimates. Judge: two 512x512 PNGs at ~350 tokens each
// (w*h/750) plus prompt and source; output includes thinking at medium
// effort. Cheat check: prompt and source only, low effort.
const EST = {
  judge: { input: 2500, output: 1500 },
  cheat: { input: 1200, output: 400 },
};

interface ExpectedOutcome {
  shouldPass: boolean;
  shouldFlag: boolean;
}

function expectedOutcome(v: Verdict): ExpectedOutcome {
  switch (v) {
    case 'correct':
    case 'almost-correct':
      // almost-correct is drift a learner should still pass on; see CALIBRATION.md.
      return { shouldPass: true, shouldFlag: false };
    case 'wrong':
      return { shouldPass: false, shouldFlag: false };
    case 'adversarial':
      return { shouldPass: false, shouldFlag: true };
  }
}

interface Split {
  seed: number;
  tuning: string[];
  heldout: string[];
}

async function selectSet(fixtures: Fixture[], set: string): Promise<Fixture[]> {
  if (set === 'all') return fixtures;
  const split = JSON.parse(await readFile(SPLIT_PATH, 'utf8')) as Split;
  const keys = new Set(set === 'heldout' ? split.heldout : split.tuning);
  return fixtures.filter((f) => keys.has(f.key));
}

// ─── Running ──────────────────────────────────────────────────────────────────

interface Usage {
  /** Model that answered (differs from the request after a refusal fallback). */
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheCreationInputTokens: number;
  cacheReadInputTokens: number;
  latencyMs: number;
}

interface LLMCall extends Usage {
  output: LLMJudgeOutput;
}

interface CheatCall extends Usage {
  output: CheatCheckOutput;
}

export interface FixtureRun {
  fixture: Fixture;
  expected: ExpectedOutcome;
  result: JudgeResult;
  /** MAE landed in the borderline band (LLM would be / was called). */
  borderline: boolean;
  /** Confident MAE pass (cheat check would be / was called). */
  confidentPass: boolean;
  llm: LLMCall | null;
  cheat: CheatCall | null;
  /** Flagged by either the visual judge or the cheat check. */
  flagged: boolean;
}

type Mode = 'mae-only' | 'live';

const MAE_ONLY_SENTINEL = 'eval: --mae-only, LLM not called';

function costOf(c: Omit<Usage, 'latencyMs'>): number {
  // A refusal fallback can answer with a model not in the table; price it
  // as the judge so the budget errs high.
  const p = PRICES[c.model] ?? PRICES[JUDGE_MODEL]!;
  return (
    (c.inputTokens * p.input +
      c.outputTokens * p.output +
      c.cacheCreationInputTokens * p.cacheWrite +
      c.cacheReadInputTokens * p.cacheRead) /
    1_000_000
  );
}

function estimate(model: string, n: number, per: { input: number; output: number }): number {
  return costOf({ model, inputTokens: n * per.input, outputTokens: n * per.output, cacheCreationInputTokens: 0, cacheReadInputTokens: 0 });
}

class BudgetExceeded extends Error {}

async function runAll(
  fixtures: Fixture[],
  challenges: Map<string, Challenge>,
  mode: Mode,
  seed: number,
  maxCost: number,
  spentSoFar: { usd: number },
): Promise<FixtureRun[]> {
  // The page calls back into Node for LLM calls. Fixtures run one at a
  // time, so one slot per call type attributes each call to its fixture.
  const slot: { call: LLMCall | null; cheat: CheatCall | null } = { call: null, cheat: null };
  const guard = (): void => {
    if (mode === 'mae-only') throw new Error(MAE_ONLY_SENTINEL);
    if (spentSoFar.usd >= maxCost) {
      throw new BudgetExceeded(`spend $${spentSoFar.usd.toFixed(2)} passed --max-cost $${maxCost}`);
    }
  };

  const session = await openHarness(async (page) => {
    await page.exposeFunction('nodeJudge', async (args: NodeJudgeArgs): Promise<LLMJudgeOutput> => {
      guard();
      const { response, ...usage } = await judgeFromPngs(args);
      const call: LLMCall = { ...usage, output: toLLMJudgeOutput(response) };
      spentSoFar.usd += costOf(call);
      slot.call = call;
      return call.output;
    });
    await page.exposeFunction('nodeCheatCheck', async (args: NodeCheatCheckArgs): Promise<CheatCheckOutput> => {
      guard();
      const { response, ...usage } = await cheatCheckFromSource(args);
      const call: CheatCall = { ...usage, output: toCheatCheckOutput(response) };
      spentSoFar.usd += costOf(call);
      slot.cheat = call;
      return call.output;
    });
  });

  const runs: FixtureRun[] = [];
  try {
    for (const [i, fixture] of fixtures.entries()) {
      const challenge = challenges.get(fixture.challengeId)!;
      const shaderSrc = await readFile(fixture.sourcePath, 'utf8');
      slot.call = null;
      slot.cheat = null;
      const args: RunJudgeArgs = { shaderSrc, challenge, uniformSeed: seed };
      const out = (await session.page.evaluate(
        (a) => (globalThis as unknown as HarnessWindow).runJudge(a),
        args,
      )) as RunJudgeOutput;


      if (out.userPngBase64) {
        await writeFile(
          fixture.sourcePath.replace(/\.glsl$/, '.png'),
          Buffer.from(out.userPngBase64, 'base64'),
        );
      }
      if (out.referencePngBase64) {
        await writeFile(
          join(FIXTURES_DIR, 'challenges', `${challenge.id}.png`),
          Buffer.from(out.referencePngBase64, 'base64'),
        );
      }

      // Set by the node callbacks during evaluate(); TS cannot see that.
      const llm = slot.call as LLMCall | null;
      const cheat = slot.cheat as CheatCall | null;
      const band = classifyByBand(out.result.maeScore).kind;
      const run: FixtureRun = {
        fixture,
        expected: expectedOutcome(fixture.verdict),
        result: out.result,
        borderline: band === 'needs-llm',
        confidentPass: band === 'confident-pass',
        llm,
        cheat,
        flagged: (llm?.output.flagged ?? false) || (cheat?.output.flagged ?? false),
      };
      runs.push(run);

      const tail =
        mode === 'live'
          ? ` llm=${llm ? llm.output.score : '-'} cheat=${cheat ? cheat.output.flagged : '-'} flagged=${run.flagged} pass=${out.result.passed} spent=$${spentSoFar.usd.toFixed(3)}`
          : ` band=${band}`;
      console.log(
        `[${i + 1}/${fixtures.length}] ${fixture.key} mae=${out.result.maeScore.toFixed(1)}${tail}`,
      );
    }
  } finally {
    await session.close();
  }
  return runs;
}

// ─── MAE-only outputs: CSV, histogram, band suggestion ──────────────────────

function csv(runs: FixtureRun[]): string {
  const rows = ['fixture,challenge,category,maeScore,maeRaw,borderline'];
  for (const r of runs) {
    rows.push(
      [
        r.fixture.key,
        r.fixture.challengeId,
        r.fixture.verdict,
        r.result.maeScore.toFixed(2),
        r.result.breakdown.maeRaw.toFixed(3),
        r.borderline,
      ].join(','),
    );
  }
  return rows.join('\n') + '\n';
}

const CATEGORY_COLORS: Record<Verdict, string> = {
  correct: '#2a9d5c',
  'almost-correct': '#4f7fd8',
  wrong: '#d0573a',
  adversarial: '#9a4fc4',
};

/** One histogram row per category, 5-point bins over 0-100, band lines overlaid. */
function histogramSvg(runs: FixtureRun[], upper: number, lower: number): string {
  const W = 720,
    rowH = 90,
    padL = 120,
    padT = 20,
    plotW = W - padL - 20;
  const bins = 20;
  const H = padT + VERDICTS.length * rowH + 40;
  const x = (score: number): number => padL + (score / 100) * plotW;
  const parts: string[] = [
    `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" font-family="system-ui, sans-serif" font-size="12">`,
    `<rect width="100%" height="100%" fill="#fff"/>`,
  ];
  VERDICTS.forEach((v, row) => {
    const scores = runs.filter((r) => r.fixture.verdict === v).map((r) => r.result.maeScore);
    const counts = new Array<number>(bins).fill(0);
    for (const s of scores) counts[Math.min(bins - 1, Math.floor(s / (100 / bins)))]! += 1;
    const max = Math.max(1, ...counts);
    const base = padT + (row + 1) * rowH - 10;
    parts.push(
      `<text x="${padL - 8}" y="${base - 30}" text-anchor="end" fill="#333">${v} (${scores.length})</text>`,
    );
    parts.push(`<line x1="${padL}" y1="${base}" x2="${padL + plotW}" y2="${base}" stroke="#999"/>`);
    counts.forEach((c, b) => {
      if (c === 0) return;
      const h = (c / max) * (rowH - 25);
      const bx = x(b * (100 / bins));
      parts.push(
        `<rect x="${bx + 1}" y="${base - h}" width="${plotW / bins - 2}" height="${h}" fill="${CATEGORY_COLORS[v]}"><title>${v}: ${c} in [${b * 5}, ${b * 5 + 5})</title></rect>`,
      );
    });
  });
  const axisY = padT + VERDICTS.length * rowH + 15;
  for (let s = 0; s <= 100; s += 10) {
    parts.push(`<text x="${x(s)}" y="${axisY}" text-anchor="middle" fill="#555">${s}</text>`);
  }
  parts.push(
    `<text x="${padL + plotW / 2}" y="${axisY + 18}" text-anchor="middle" fill="#333">MAE score</text>`,
  );
  const bandLines: [number, string, number][] = [
    [lower, `lowerBand ${lower}`, padT + 10],
    [upper, `upperBand ${upper}`, padT + 26],
  ];
  for (const [val, label, labelY] of bandLines) {
    parts.push(`<line x1="${x(val)}" y1="${padT}" x2="${x(val)}" y2="${axisY - 12}" stroke="#222" stroke-dasharray="4 3"/>`);
    parts.push(`<text x="${x(val) + 4}" y="${labelY}" fill="#222">${label}</text>`);
  }
  parts.push('</svg>');
  return parts.join('\n');
}

interface BandSuggestion {
  upperBand: number;
  lowerBand: number;
  note: string;
  leaks: FixtureRun[];
}

/**
 * Rule from the eval plan, with two adjustments:
 *   upperBand = lowest score no `wrong` fixture reaches (max wrong + 1)
 *   lowerBand = highest score no correct / almost-correct fixture falls under (their min),
 *               raised to the floor below which the LLM cannot change the outcome:
 *               (passThreshold - llmWeight * 100) / maeWeight
 * Adversarial fixtures that land at or above upperBand skip the LLM and are
 * reported as expected leaks instead of dragging upperBand above 100.
 */
function suggestBands(runs: FixtureRun[]): BandSuggestion {
  const score = (r: FixtureRun): number => r.result.maeScore;
  const wrong = runs.filter((r) => r.fixture.verdict === 'wrong').map(score);
  const good = runs.filter((r) => r.expected.shouldPass).map(score);
  const { passThreshold, llmWeight, maeWeight } = DEFAULT_BANDS;
  const floor = Math.max(0, Math.ceil((passThreshold - llmWeight * 100) / maeWeight));
  let upperBand = Math.min(100, Math.floor(Math.max(0, ...wrong)) + 1);
  const ruleLower = Math.floor(Math.min(100, ...good));
  let lowerBand = Math.max(ruleLower, floor);
  const notes = [`Rule gives lowerBand ${ruleLower}; scoring floor is ${floor} (below it the LLM cannot lift a submission to passThreshold).`];
  if (lowerBand > upperBand) {
    notes.push(`lowerBand ${lowerBand} > upperBand ${upperBand}: no borderline zone; swapped them so the gap goes to the LLM.`);
    [upperBand, lowerBand] = [lowerBand, upperBand];
  }
  const leaks = runs.filter((r) => r.fixture.verdict === 'adversarial' && score(r) >= upperBand);
  return { upperBand, lowerBand, note: notes.join(' '), leaks };
}

interface ToleranceSuggestion {
  challengeId: string;
  current: number;
  suggested: number;
  worstGoodRaw: number;
  closestWrongRaw: number;
  separable: boolean;
}

/**
 * Per-challenge tolerance from raw MAE, given the bands. score = 100 * (1 - raw / tol), so:
 *   worst good fixture scores >= upperBand  needs  tol >= worstGood / (1 - upper / 100)
 *   closest wrong fixture scores < lowerBand  needs  tol <  closestWrong / (1 - lower / 100)
 * When both hold, take the geometric middle of the range. When they can't
 * both hold, take the lower bound: good fixtures still pass outright and the
 * closest wrong ones land in the band, where the visual judge decides.
 */
function suggestTolerances(runs: FixtureRun[], challenges: Map<string, Challenge>): ToleranceSuggestion[] {
  const { upperBand, lowerBand } = DEFAULT_BANDS;
  const out: ToleranceSuggestion[] = [];
  for (const [id, challenge] of challenges) {
    const mine = runs.filter((r) => r.fixture.challengeId === id);
    const good = mine.filter((r) => r.expected.shouldPass).map((r) => r.result.breakdown.maeRaw);
    const wrong = mine.filter((r) => r.fixture.verdict === 'wrong').map((r) => r.result.breakdown.maeRaw);
    if (good.length === 0 || wrong.length === 0) continue;
    const worstGoodRaw = Math.max(...good);
    const closestWrongRaw = Math.min(...wrong);
    const lo = worstGoodRaw / (1 - upperBand / 100);
    const hi = closestWrongRaw / (1 - lowerBand / 100);
    const separable = lo < hi;
    const raw = separable ? Math.sqrt(lo * hi) : lo;
    out.push({
      challengeId: id,
      current: challenge.tolerance,
      suggested: Math.ceil(raw * 10) / 10,
      worstGoodRaw,
      closestWrongRaw,
      separable,
    });
  }
  return out;
}

// ─── Live report ──────────────────────────────────────────────────────────────

function pct(n: number, d: number): string {
  return d === 0 ? 'n/a' : `${((n / d) * 100).toFixed(1)}%`;
}

function percentile(xs: number[], p: number): number {
  if (xs.length === 0) return 0;
  const s = [...xs].sort((a, b) => a - b);
  return s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))]!;
}

interface RepeatStats {
  label: string;
  runs: FixtureRun[];
}

function metrics(runs: FixtureRun[]) {
  const shouldFail = runs.filter((r) => !r.expected.shouldPass);
  const shouldPass = runs.filter((r) => r.expected.shouldPass);
  const adv = runs.filter((r) => r.fixture.verdict === 'adversarial');
  const advPassed = adv.filter((r) => r.result.passed);
  const judgeCalls = runs.flatMap((r) => (r.llm ? [r.llm] : []));
  const cheatCalls = runs.flatMap((r) => (r.cheat ? [r.cheat] : []));
  const allCalls: Usage[] = [...judgeCalls, ...cheatCalls];
  const judgeCost = judgeCalls.reduce((s, c) => s + costOf(c), 0);
  const cheatCost = cheatCalls.reduce((s, c) => s + costOf(c), 0);
  return {
    total: runs.length,
    falsePass: shouldFail.filter((r) => r.result.passed).length,
    shouldFail: shouldFail.length,
    falseFail: shouldPass.filter((r) => !r.result.passed).length,
    shouldPass: shouldPass.length,
    adv: adv.length,
    advLeakNoCheck: advPassed.filter((r) => !r.llm && !r.cheat).length,
    advLeakCheat: advPassed.filter((r) => r.cheat).length,
    advLeakJudge: advPassed.filter((r) => r.llm).length,
    advSeenByJudge: adv.filter((r) => r.llm).length,
    advFlaggedByJudge: adv.filter((r) => r.llm?.output.flagged).length,
    advSeenByCheat: adv.filter((r) => r.cheat).length,
    advFlaggedByCheat: adv.filter((r) => r.cheat?.output.flagged).length,
    goodFlaggedByCheat: shouldPass.filter((r) => r.cheat?.output.flagged).length,
    goodSeenByCheat: shouldPass.filter((r) => r.cheat).length,
    skipped: runs.filter((r) => !r.llm && !r.cheat).length,
    judgeCalls: judgeCalls.length,
    cheatCalls: cheatCalls.length,
    llmUnavailable: runs.filter((r) => r.result.breakdown.llmUnavailable).length,
    cheatUnavailable: runs.filter((r) => r.confidentPass && !r.cheat).length,
    inputTokens: allCalls.reduce((s, c) => s + c.inputTokens + c.cacheCreationInputTokens + c.cacheReadInputTokens, 0),
    outputTokens: allCalls.reduce((s, c) => s + c.outputTokens, 0),
    judgeCost,
    cheatCost,
    totalCost: judgeCost + cheatCost,
    fallbackAnswers: allCalls.filter((c) => c.model !== JUDGE_MODEL && c.model !== CHEAT_CHECK_MODEL).length,
    judgeP50: percentile(runs.map((r) => r.result.judgeLatencyMs), 50),
    judgeP95: percentile(runs.map((r) => r.result.judgeLatencyMs), 95),
    llmP50: percentile(judgeCalls.map((c) => c.latencyMs), 50),
    llmP95: percentile(judgeCalls.map((c) => c.latencyMs), 95),
    cheatP50: percentile(cheatCalls.map((c) => c.latencyMs), 50),
    cheatP95: percentile(cheatCalls.map((c) => c.latencyMs), 95),
  };
}

function confusionTable(runs: FixtureRun[]): string[] {
  const lines = [
    '| Category | n | Passed | Failed | Visual judge | Cheat check | Flagged | Correct verdict |',
    '| --- | --- | --- | --- | --- | --- | --- | --- |',
  ];
  for (const v of VERDICTS) {
    const rs = runs.filter((r) => r.fixture.verdict === v);
    const exp = expectedOutcome(v);
    const passed = rs.filter((r) => r.result.passed).length;
    const correct = rs.filter((r) => r.result.passed === exp.shouldPass).length;
    lines.push(
      `| ${v} (expect ${exp.shouldPass ? 'pass' : 'fail'}) | ${rs.length} | ${passed} | ${rs.length - passed} | ${rs.filter((r) => r.llm).length} | ${rs.filter((r) => r.cheat).length} | ${rs.filter((r) => r.flagged).length} | ${pct(correct, rs.length)} |`,
    );
  }
  return lines;
}

function renderReport(sets: RepeatStats[], seed: number, commit: string, startedAt: Date): string {
  const L: string[] = [];
  L.push('# Judge eval report', '');
  L.push(`- Run started: ${startedAt.toISOString()}`);
  L.push(`- Commit: \`${commit}\``);
  L.push(`- Models: visual judge \`${JUDGE_MODEL}\`, cheat check \`${CHEAT_CHECK_MODEL}\``);
  L.push(
    `- Bands: upper ${DEFAULT_BANDS.upperBand}, lower ${DEFAULT_BANDS.lowerBand}, pass threshold ${DEFAULT_BANDS.passThreshold}, weights MAE ${DEFAULT_BANDS.maeWeight} / LLM ${DEFAULT_BANDS.llmWeight}`,
  );
  L.push(`- Uniform seed: ${seed} (4 samples: defaults + 3 random u_time/u_mouse)`);
  L.push(`- Renderer: headless Chromium, SwiftShader WebGL2`, '');
  L.push(
    'Rates are conditional: false-pass rate = passed / fixtures that should fail (wrong + adversarial); false-fail rate = failed / fixtures that should pass (correct + almost-correct).',
    '',
  );

  for (const { label, runs } of sets) {
    const m = metrics(runs);
    L.push(`## ${label}`, '');
    L.push(...confusionTable(runs), '');
    L.push(`- False-pass rate: ${pct(m.falsePass, m.shouldFail)} (${m.falsePass}/${m.shouldFail})`);
    L.push(`- False-fail rate: ${pct(m.falseFail, m.shouldPass)} (${m.falseFail}/${m.shouldPass})`);
    L.push(
      `- Adversarial leak rate: ${pct(m.advLeakNoCheck + m.advLeakCheat + m.advLeakJudge, m.adv)} (${m.advLeakCheat} passed the cheat check, ${m.advLeakJudge} passed the visual judge, ${m.advLeakNoCheck} reached no LLM)`,
    );
    L.push(`- Adversarial flagged by the visual judge: ${m.advFlaggedByJudge}/${m.advSeenByJudge} it saw`);
    L.push(`- Adversarial flagged by the cheat check: ${m.advFlaggedByCheat}/${m.advSeenByCheat} it saw`);
    L.push(`- Good fixtures wrongly flagged by the cheat check: ${m.goodFlaggedByCheat}/${m.goodSeenByCheat} it saw`);
    L.push(`- Reached no LLM (confident MAE fail): ${pct(m.skipped, m.total)} (${m.skipped}/${m.total})`);
    L.push(
      `- LLM calls: ${m.judgeCalls} visual judge, ${m.cheatCalls} cheat check${m.llmUnavailable ? `; ${m.llmUnavailable} judge calls failed and fell back to MAE` : ''}${m.cheatUnavailable ? `; ${m.cheatUnavailable} cheat checks failed (pass stood)` : ''}${m.fallbackAnswers ? `; ${m.fallbackAnswers} answered by a refusal fallback model` : ''}`,
    );
    L.push(`- Tokens: ${m.inputTokens} input, ${m.outputTokens} output (output includes thinking)`);
    L.push(
      `- Cost: $${m.totalCost.toFixed(3)} total (judge $${m.judgeCost.toFixed(3)}, cheat check $${m.cheatCost.toFixed(4)}), $${(m.totalCost / Math.max(1, m.total)).toFixed(4)} per graded submission`,
    );
    L.push(`- Judge latency (render + MAE + LLMs): p50 ${m.judgeP50.toFixed(0)} ms, p95 ${m.judgeP95.toFixed(0)} ms`);
    L.push(`- Visual judge call latency: p50 ${m.llmP50.toFixed(0)} ms, p95 ${m.llmP95.toFixed(0)} ms`);
    L.push(`- Cheat check call latency: p50 ${m.cheatP50.toFixed(0)} ms, p95 ${m.cheatP95.toFixed(0)} ms`, '');
  }

  const repeats = sets.filter((s) => s.label.startsWith('Held-out run'));
  if (repeats.length > 1) {
    L.push('## Spread across repeated held-out runs', '');
    const fp = repeats.map((s) => {
      const m = metrics(s.runs);
      return (m.falsePass / Math.max(1, m.shouldFail)) * 100;
    });
    const ff = repeats.map((s) => {
      const m = metrics(s.runs);
      return (m.falseFail / Math.max(1, m.shouldPass)) * 100;
    });
    L.push(`- False-pass rate per run: ${fp.map((x) => x.toFixed(1) + '%').join(', ')}`);
    L.push(`- False-fail rate per run: ${ff.map((x) => x.toFixed(1) + '%').join(', ')}`);
    const byKey = new Map<string, boolean[]>();
    for (const s of repeats)
      for (const r of s.runs)
        byKey.set(r.fixture.key, [...(byKey.get(r.fixture.key) ?? []), r.result.passed]);
    const flips = [...byKey.entries()].filter(([, v]) => new Set(v).size > 1).map(([k]) => k);
    L.push(
      `- Fixtures whose verdict changed between runs: ${flips.length}${flips.length ? ` (${flips.map((k) => `\`${k}\``).join(', ')})` : ''}`,
      '',
    );
  }

  const detail = sets[0]!;
  L.push(`## Per-fixture detail (${detail.label})`, '');
  L.push(
    '| Fixture | MAE | LLM | Cheat check | Flagged | Final | Passed | Expected | Reasoning |',
    '| --- | --- | --- | --- | --- | --- | --- | --- | --- |',
  );
  for (const r of detail.runs) {
    const reasoning = (r.result.breakdown.llmReasoning ?? '')
      .replace(/\|/g, '\\|')
      .replace(/\n/g, ' ')
      .slice(0, 140);
    const ok = r.result.passed === r.expected.shouldPass ? '' : ' **x**';
    L.push(
      `| \`${r.fixture.key}\` | ${r.result.maeScore.toFixed(1)} | ${r.llm ? r.llm.output.score : '-'} | ${r.cheat ? (r.cheat.output.flagged ? 'flagged' : 'clean') : '-'} | ${r.flagged} | ${r.result.finalScore} | ${r.result.passed}${ok} | ${r.expected.shouldPass ? 'pass' : 'fail'} | ${reasoning} |`,
    );
  }
  L.push('');
  return L.join('\n');
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function arg(name: string): string | undefined {
  return process.argv.find((a) => a.startsWith(`--${name}=`))?.split('=')[1];
}

async function main(): Promise<void> {
  const mode: Mode | 'dry' = process.argv.includes('--live')
    ? 'live'
    : process.argv.includes('--mae-only')
      ? 'mae-only'
      : 'dry';
  const set = arg('set') ?? 'all';
  const seed = Number(arg('seed') ?? 1337);
  const repeat = Number(arg('repeat') ?? 1);
  const maxCost = Number(arg('max-cost') ?? 5);

  const challenges = await loadChallenges();
  const all = await discoverFixtures(new Set(challenges.keys()));
  const fixtures = await selectSet(all, set);

  console.log(`Challenges: ${challenges.size}. Fixtures in set "${set}": ${fixtures.length}`);
  for (const v of VERDICTS)
    console.log(`  ${v}: ${fixtures.filter((f) => f.verdict === v).length}`);
  if (mode === 'dry') {
    console.log('\nDry run. Pass --mae-only (free) or --live (calls the Anthropic API).');
    return;
  }

  await mkdir(OUT_DIR, { recursive: true });
  const spent = { usd: 0 };

  if (mode === 'mae-only') {
    const runs = await runAll(fixtures, challenges, 'mae-only', seed, 0, spent);
    const bands = suggestBands(runs);
    await writeFile(join(OUT_DIR, `mae-${set}.csv`), csv(runs));
    await writeFile(
      join(HERE, `mae-histogram-${set}.svg`),
      histogramSvg(runs, bands.upperBand, bands.lowerBand),
    );
    const wouldCall = runs.filter((r) => r.borderline).length;
    const wouldCheck = runs.filter((r) => r.confidentPass).length;
    console.log(`\nWrote out/mae-${set}.csv and mae-histogram-${set}.svg`);
    console.log(
      `With current DEFAULT_BANDS (${DEFAULT_BANDS.upperBand}/${DEFAULT_BANDS.lowerBand}): ${wouldCall} visual judge calls, ${wouldCheck} cheat checks, ${runs.length - wouldCall - wouldCheck} reach no LLM`,
    );
    for (const v of VERDICTS) {
      const s = runs.filter((r) => r.fixture.verdict === v).map((r) => r.result.maeScore);
      if (s.length)
        console.log(
          `  ${v.padEnd(15)} min ${Math.min(...s).toFixed(1)}  p50 ${percentile(s, 50).toFixed(1)}  max ${Math.max(...s).toFixed(1)}`,
        );
    }
    console.log(
      `Suggested bands: upper ${bands.upperBand}, lower ${bands.lowerBand}. ${bands.note}`,
    );
    const inBand = runs.filter(
      (r) => r.result.maeScore >= bands.lowerBand && r.result.maeScore < bands.upperBand,
    ).length;
    console.log(
      `  with suggested bands: ${inBand} visual judge calls`,
    );
    console.log(`\nTolerances (worst good raw MAE -> >= upperBand, closest wrong -> < lowerBand):`);
    for (const t of suggestTolerances(runs, challenges)) {
      console.log(
        `  ${t.challengeId.padEnd(18)} current ${String(t.current).padStart(5)}  suggested ${String(t.suggested).padStart(6)}  (good max ${t.worstGoodRaw.toFixed(2)}, wrong min ${t.closestWrongRaw.toFixed(2)}${t.separable ? '' : ', not separable: closest wrong goes to the visual judge'})`,
      );
    }
    console.log(
      `  adversarial at/above upperBand (only the cheat check reads them): ${bands.leaks.map((r) => r.fixture.key).join(', ') || 'none'}`,
    );
    return;
  }

  // Live. Pre-flight with a free MAE-only pass to count calls and estimate cost.
  const pre = await runAll(fixtures, challenges, 'mae-only', seed, 0, spent);
  const judgeN = pre.filter((r) => r.borderline).length * repeat;
  const cheatN = pre.filter((r) => r.confidentPass).length * repeat;
  const estCost = estimate(JUDGE_MODEL, judgeN, EST.judge) + estimate(CHEAT_CHECK_MODEL, cheatN, EST.cheat);
  console.log(
    `\nPre-flight (${repeat} run(s)): ${judgeN} visual judge calls (~${judgeN * EST.judge.input} in / ~${judgeN * EST.judge.output} out tokens), ${cheatN} cheat checks (~${cheatN * EST.cheat.input} in / ~${cheatN * EST.cheat.output} out). Est. $${estCost.toFixed(2)} (cap $${maxCost}).`,
  );
  if (estCost > maxCost)
    throw new Error(`estimated cost $${estCost.toFixed(2)} exceeds --max-cost $${maxCost}`);
  if (!process.argv.includes('--yes')) {
    console.log('Starting in 10s. Ctrl-C to abort, or pass --yes to skip this pause.');
    await new Promise((r) => setTimeout(r, 10_000));
  }

  const startedAt = new Date();
  const sets: RepeatStats[] = [];
  const labelFor = (i: number): string =>
    set === 'heldout' ? `Held-out run ${i + 1}` : `${set} set${repeat > 1 ? ` run ${i + 1}` : ''}`;
  for (let i = 0; i < repeat; i++) {
    const runs = await runAll(fixtures, challenges, 'live', seed, maxCost, spent);
    sets.push({ label: labelFor(i), runs });
    await writeFile(join(OUT_DIR, `live-${set}-${i + 1}.json`), JSON.stringify(runs, null, 2));
  }

  const commit = execSync('git rev-parse HEAD', { encoding: 'utf8' }).trim();
  const reportPath = arg('report') ? join(HERE, arg('report')!) : REPORT_PATH;
  await writeFile(reportPath, renderReport(sets, seed, commit, startedAt));
  console.log(`\nReport written to ${reportPath}. Total spend $${spent.usd.toFixed(3)}.`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
