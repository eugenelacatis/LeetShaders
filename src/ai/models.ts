// AI Systems & Integration. Single source of truth for model strings.
//
// Imported by both the browser client (anthropic.ts) and the node eval
// client (eval/anthropicNode.ts). No DOM or node imports here so both
// tsconfig projects can type-check it. CLAUDE.md warns that tooling will
// suggest older names from training data; override here only.

/** Vision judge for borderline MAE scores. */
export const JUDGE_MODEL = 'claude-opus-5-5';
/** Hints. */
export const HINT_MODEL = 'claude-sonnet-5-5';
/** Source-only cheat check on submissions that pass on MAE alone. */
export const CHEAT_CHECK_MODEL = 'claude-haiku-5-5';

export type AnthropicModel = typeof JUDGE_MODEL | typeof HINT_MODEL | typeof CHEAT_CHECK_MODEL;

/** output_config.effort. These models always think; effort sets how much. */
export type Effort = 'low' | 'medium' | 'high';

/**
 * Server-side refusal fallback applies to Opus 5.5 and Sonnet 5.5 on the
 * Claude API. Haiku 5.5 has none; its refusals surface as errors.
 */
export function supportsRefusalFallback(model: AnthropicModel): boolean {
  return model === JUDGE_MODEL || model === HINT_MODEL;
}
