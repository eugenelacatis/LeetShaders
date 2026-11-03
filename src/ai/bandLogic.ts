// AI Systems & Integration. Band logic for the two-stage judge.
// See AI_SYSTEMS.md task 3.
//
// This module owns the decision tree only. combiner.ts calls
// `applyBandLogic` after stage-one MAE scoring and passes a thunk that
// invokes the LLM judge with the renders it already has in hand.
//
// Band values and per-challenge tolerances were calibrated together on
// 2026-11-02 against the tuning fixtures in src/ai/eval (see
// eval/CALIBRATION.md, v1):
//
// - lowerBand 60: with maeWeight 0.5, llmWeight 0.5 and passThreshold 80,
//   a submission needs MAE >= (80 - 0.5 * 100) / 0.5 = 60 to pass even with
//   a perfect LLM score. Visual-judge calls below 60 can only confirm a
//   fail, so they are skipped. Revisit this floor whenever the weights or
//   threshold change.
// - upperBand 70: each challenge's tolerance is set so its worst
//   correct/almost-correct tuning fixture scores >= 70 and its closest
//   wrong one scores < 60 (`run.ts --mae-only` prints the derivation).
//   circle-sdf can't fully separate; its closest wrong fixture lands in the
//   band and the visual judge decides.
//
// combiner.ts also passes a source-only cheat check that runs on every
// score >= upperBand, because cheats such as baked color tables render well
// enough to clear MAE.

import type { CheatCheckOutput, LLMJudgeOutput } from '../judge/types';

export interface BandConfig {
  /** MAE score >= this returns pass without invoking the LLM. */
  upperBand: number;
  /** MAE score < this returns fail without invoking the LLM. */
  lowerBand: number;
  /** Weight on MAE in the final combined score. maeWeight + llmWeight should sum to 1. */
  maeWeight: number;
  /** Weight on the LLM visualMatchScore in the final combined score. */
  llmWeight: number;
  /** Final score threshold for passing when both stages ran. */
  passThreshold: number;
}

export const DEFAULT_BANDS: BandConfig = {
  upperBand: 70,
  lowerBand: 60,
  maeWeight: 0.5,
  llmWeight: 0.5,
  passThreshold: 80,
};

export type BandClassification =
  | { kind: 'confident-pass' }
  | { kind: 'confident-fail' }
  | { kind: 'needs-llm' };

/**
 * Classify an MAE score against the band thresholds. Pure function,
 * no side effects, safe to call from anywhere.
 */
export function classifyByBand(
  maeScore: number,
  config: BandConfig = DEFAULT_BANDS,
): BandClassification {
  if (maeScore >= config.upperBand) return { kind: 'confident-pass' };
  if (maeScore < config.lowerBand) return { kind: 'confident-fail' };
  return { kind: 'needs-llm' };
}

/**
 * Weighted combine of MAE and LLM scores. Both inputs are 0-100.
 * Result clamped to [0, 100]. Pure.
 */
export function combineScores(
  maeScore: number,
  llmScore: number,
  config: BandConfig = DEFAULT_BANDS,
): number {
  const combined = maeScore * config.maeWeight + llmScore * config.llmWeight;
  return Math.max(0, Math.min(100, combined));
}

export interface ApplyBandLogicInput {
  maeScore: number;
  /** Thunk the caller (combiner.ts) provides. Kept as a zero-arg
   *  function so judge can close over the renders it already has
   *  without bandLogic needing to know about Uint8Arrays. */
  callLLM: () => Promise<LLMJudgeOutput>;
  /** Optional source-only cheat check, run on confident passes. A flag fails
   *  the submission; an error leaves the MAE pass standing. */
  callCheatCheck?: () => Promise<CheatCheckOutput>;
  config?: BandConfig;
}

export interface ApplyBandLogicResult {
  llmInvoked: boolean;
  llmResult: LLMJudgeOutput | null;
  llmUnavailable: boolean;
  /** Result of the cheat check when it ran and answered; null otherwise. */
  cheatCheck: CheatCheckOutput | null;
  finalScore: number;
  passed: boolean;
  trace?: string;
}

/**
 * Run the full decision tree. Short-circuits the LLM call when MAE
 * is confidently one side of the bands. When flagged by the LLM,
 * returns fail regardless of the visual score - cheating overrides
 * pixel accuracy.
 */
export async function applyBandLogic(input: ApplyBandLogicInput): Promise<ApplyBandLogicResult> {
  const config = input.config ?? DEFAULT_BANDS;
  const classification = classifyByBand(input.maeScore, config);

  if (classification.kind === 'confident-pass') {
    const pass = {
      llmInvoked: false,
      llmResult: null,
      llmUnavailable: false,
      cheatCheck: null,
      finalScore: input.maeScore,
      passed: true,
      trace: `MAE ${input.maeScore.toFixed(1)} >= upperBand ${config.upperBand}, skipped visual LLM.`,
    };
    if (!input.callCheatCheck) return pass;

    // A shader can render well by cheating (a baked color table, an
    // injected "grade this 100" comment), so passes still get their source
    // read. Fail open: if the check is unavailable, the MAE pass stands.
    let cheatCheck: CheatCheckOutput;
    try {
      cheatCheck = await input.callCheatCheck();
    } catch (err) {
      return {
        ...pass,
        trace: `${pass.trace} Cheat check unavailable (${err instanceof Error ? err.message : String(err)}).`,
      };
    }
    if (cheatCheck.flagged) {
      return {
        ...pass,
        cheatCheck,
        finalScore: 0,
        passed: false,
        trace: `Flagged by cheat check: ${cheatCheck.reasoning}`,
      };
    }
    return { ...pass, cheatCheck, trace: `${pass.trace} Cheat check clean.` };
  }

  if (classification.kind === 'confident-fail') {
    return {
      llmInvoked: false,
      llmResult: null,
      llmUnavailable: false,
      cheatCheck: null,
      finalScore: input.maeScore,
      passed: false,
      trace: `MAE ${input.maeScore.toFixed(1)} < lowerBand ${config.lowerBand}, skipped LLM.`,
    };
  }

  // Borderline — invoke LLM and combine scores. If the LLM call fails
  // (network, rate limit, API key issue), fall back to MAE-only scoring
  // so the submit flow never hangs. The breakdown will flag this for the UI.
  let llmResult: LLMJudgeOutput | null = null;
  let llmUnavailable = false;

  try {
    llmResult = await input.callLLM();
  } catch (err) {
    llmUnavailable = true;
    // Fallback: treat as if LLM was never invoked, score on MAE alone.
    const passed = input.maeScore >= config.passThreshold;
    return {
      llmInvoked: false,
      llmResult: null,
      llmUnavailable,
      cheatCheck: null,
      finalScore: input.maeScore,
      passed,
      trace: `LLM unavailable (${err instanceof Error ? err.message : String(err)}), scored on MAE only`,
    };
  }

  // Flagged shaders (cheating detected) always fail.
  if (llmResult.flagged) {
    return {
      llmInvoked: true,
      llmResult,
      llmUnavailable,
      cheatCheck: null,
      finalScore: 0,
      passed: false,
      trace: `Flagged by LLM: ${llmResult.reasoning}`,
    };
  }

  const finalScore = combineScores(input.maeScore, llmResult.score, config);
  const passed = finalScore >= config.passThreshold;
  return {
    llmInvoked: true,
    llmResult,
    llmUnavailable,
    cheatCheck: null,
    finalScore,
    passed,
    trace: `MAE ${input.maeScore.toFixed(1)} + LLM ${llmResult.score} -> ${finalScore.toFixed(1)} (threshold ${config.passThreshold}).`,
  };
}
