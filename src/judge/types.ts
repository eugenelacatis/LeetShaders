/**
 * Tracks in learning order. Each challenge belongs to exactly one. `capstone` is
 * the last board: each of its challenges mixes skills from two earlier tracks.
 */
export const TRACKS = ['color', 'shapes', 'combining', 'patterns', 'noise', 'raymarching', 'capstone'] as const;
export type Track = (typeof TRACKS)[number];

/** Credit for an adapted shader. A challenge can list several (forks, embedded code). */
export interface ChallengeSource {
  title: string;
  author: string;
  url: string;
  license: string;
}

export interface Challenge {
  id: string;
  slug: string;
  title: string;
  description: string;
  /** `expert` marks a track's boss key and every capstone. */
  difficulty: 'beginner' | 'intermediate' | 'advanced' | 'expert';
  track: Track;
  /** Capstones only: the earlier tracks this challenge draws on. */
  mixes?: Track[];
  referenceShaderSrc: string;
  /** Capstones: scene code with `@cell` regions to fill in. Others use the shared starter. */
  starterSrc?: string;
  tolerance: number;
  useBlur: boolean;
  hintText?: string;
  source?: ChallengeSource[];
}

export interface JudgeResult {
  maeScore: number;
  llmScore: number | null;
  finalScore: number;
  passed: boolean;
  breakdown: {
    maeRaw: number;
    llmReasoning?: string;
    stageTwoInvoked: boolean;
    llmUnavailable?: boolean;
    /** True when a confident MAE pass was sent to the source-only cheat check. */
    cheatCheckInvoked?: boolean;
  };
  renderLatencyMs: number;
  judgeLatencyMs: number;
}

export interface MAEResult {
  score: number;
  rawMae: number;
  blurApplied: boolean;
}

export interface LLMJudgeInput {
  userRender: Uint8Array;
  referenceRender: Uint8Array;
  userShaderSrc: string;
  challenge: Challenge;
}

export interface LLMJudgeOutput {
  score: number;
  reasoning: string;
  flagged: boolean;
}

export type LLMJudgeFn = (input: LLMJudgeInput) => Promise<LLMJudgeOutput>;

export interface CheatCheckInput {
  userShaderSrc: string;
  challenge: Challenge;
}

export interface CheatCheckOutput {
  flagged: boolean;
  reasoning: string;
}

/** Source-only cheat check run on submissions that pass on MAE alone. */
export type CheatCheckFn = (input: CheatCheckInput) => Promise<CheatCheckOutput>;

export interface ShaderCompileError {
  type: 'compile_error';
  message: string;
  errors: { line: number; message: string }[];
}

export interface ShaderTimeoutError {
  type: 'timeout';
  message: string;
}

export interface ShaderContextLostError {
  type: 'context_lost';
  message: string;
}

export type ShaderError = ShaderCompileError | ShaderTimeoutError | ShaderContextLostError;

export interface PipelineError {
  kind: 'compile-error' | 'link-error' | 'context-lost' | 'timeout';
  line?: number;
  column?: number;
  message: string;
}

export function shaderErrorToPipelineErrors(err: ShaderError): PipelineError[] {
  if (err.type === 'compile_error') {
    if (err.errors.length === 0) {
      return [{ kind: 'compile-error', message: err.message }];
    }
    return err.errors.map((e) => ({
      kind: 'compile-error' as const,
      line: e.line,
      message: e.message,
    }));
  }
  if (err.type === 'timeout') {
    return [{ kind: 'timeout', message: err.message }];
  }
  return [{ kind: 'context-lost', message: err.message }];
}
