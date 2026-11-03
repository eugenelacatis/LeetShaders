// AI Systems & Integration. Single source of truth for model strings.
//
// Imported by both the browser client (anthropic.ts) and the node eval
// client (eval/anthropicNode.ts). No DOM or node imports here so both
// tsconfig projects can type-check it. CLAUDE.md warns that tooling will
// suggest older names from training data; override here only.

export const JUDGE_MODEL = 'claude-opus-4-7';
export const HINT_MODEL = 'claude-sonnet-4-6';

export type AnthropicModel = typeof JUDGE_MODEL | typeof HINT_MODEL;
