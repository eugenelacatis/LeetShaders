import { compileAndRender, type Uniforms } from './pipeline';
import { computeMAEResult } from './mae';
import type { Challenge, JudgeResult, LLMJudgeFn, MAEResult } from './types';
import { applyBandLogic, DEFAULT_BANDS, type BandConfig } from '../ai/bandLogic';

// ─── Plumbing only ────────────────────────────────────────────────────────────
// Band thresholds, weights, and the pass threshold live in src/ai/bandLogic.ts
// (owned by AI Systems & Integration). This file owns pipeline orchestration:
// compile both shaders, compute MAE, hand the decision to applyBandLogic, and
// shape the result as JudgeResult for consumers.
//
// Callers may pass a custom BandConfig for tests or experiments; production
// uses DEFAULT_BANDS.
//
// uniformSamples: both shaders are rendered at every sample and the worst MAE
// score is kept, so a shader that only matches at the default inputs fails.
// The LLM sees the renders from that worst sample. The default single empty
// sample keeps the original one-render behavior.

export async function judge(
  userShaderSrc: string,
  challenge: Challenge,
  llmJudge: LLMJudgeFn,
  bandConfig: BandConfig = DEFAULT_BANDS,
  uniformSamples: Uniforms[] = [{}],
): Promise<JudgeResult> {
  const judgeStart = performance.now();

  // Stage 0 + 1: compile and render both shaders at each sample (with
  // watchdog), score MAE per sample, keep the worst.
  const renderStart = performance.now();
  let worst: {
    userRender: Uint8Array;
    refRender: Uint8Array;
    maeResult: MAEResult;
  } | null = null;

  for (const uniforms of uniformSamples) {
    const userResult = compileAndRender(userShaderSrc, uniforms);
    if ('type' in userResult) {
      return failResult(0, userResult.message, performance.now() - renderStart, 0);
    }

    const refResult = compileAndRender(challenge.referenceShaderSrc, uniforms);
    if ('type' in refResult) {
      return failResult(0, `Reference shader error: ${refResult.message}`, performance.now() - renderStart, 0);
    }

    const maeResult = computeMAEResult(userResult.pixels, refResult.pixels, challenge.tolerance, challenge.useBlur);
    if (!worst || maeResult.score < worst.maeResult.score) {
      worst = { userRender: userResult.pixels, refRender: refResult.pixels, maeResult };
    }
  }
  const renderLatencyMs = performance.now() - renderStart;

  if (!worst) {
    return failResult(0, 'No uniform samples to render', renderLatencyMs, 0);
  }
  const { userRender, refRender, maeResult } = worst;
  const maeScore = maeResult.score;

  // Stage 2 decision tree — delegated to bandLogic so calibration and
  // production share a single source of truth for thresholds and weights.
  const band = await applyBandLogic({
    maeScore,
    config: bandConfig,
    callLLM: () => llmJudge({
      userRender,
      referenceRender: refRender,
      userShaderSrc,
      challenge,
    }),
  });

  return {
    maeScore,
    llmScore: band.llmResult?.score ?? null,
    finalScore: Math.round(band.finalScore),
    passed: band.passed,
    breakdown: {
      maeRaw: maeResult.rawMae,
      llmReasoning: band.llmResult?.reasoning,
      stageTwoInvoked: band.llmInvoked,
      llmUnavailable: band.llmUnavailable ? true : undefined,
    },
    renderLatencyMs,
    judgeLatencyMs: performance.now() - judgeStart,
  };
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

function failResult(
  score: number,
  reason: string,
  renderLatencyMs: number,
  judgeLatencyMs: number,
): JudgeResult {
  return {
    maeScore: score,
    llmScore: null,
    finalScore: score,
    passed: false,
    breakdown: { maeRaw: 0, llmReasoning: reason, stageTwoInvoked: false },
    renderLatencyMs,
    judgeLatencyMs,
  };
}
