// Types shared by the Node half (run.ts, gen/) and the browser half
// (browser/harness.ts) of the eval harness. Pure: no DOM or node imports.

import type { Challenge, CheatCheckOutput, JudgeResult, LLMJudgeOutput } from '../../judge/types';

export interface NodeJudgeArgs {
  challenge: Challenge;
  userShaderSrc: string;
  userPngBase64: string;
  referencePngBase64: string;
}

export interface NodeCheatCheckArgs {
  challenge: Challenge;
  userShaderSrc: string;
}

export interface RunJudgeArgs {
  shaderSrc: string;
  challenge: Challenge;
  /** Seed for sampleUniforms(); the page draws the samples. */
  uniformSeed: number;
}

export interface RunJudgeOutput {
  result: JudgeResult;
  /** Renders at the default inputs (sample 0), for inspection. Null on compile error. */
  userPngBase64: string | null;
  referencePngBase64: string | null;
}

export interface HarnessWindow {
  nodeJudge: (args: NodeJudgeArgs) => Promise<LLMJudgeOutput>;
  nodeCheatCheck: (args: NodeCheatCheckArgs) => Promise<CheatCheckOutput>;
  runJudge: (args: RunJudgeArgs) => Promise<RunJudgeOutput>;
  renderGrid: (src: string, n: number) => number[] | null;
  harnessReady: boolean;
}
