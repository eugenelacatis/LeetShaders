// AI Systems & Integration owns this file. See AI_SYSTEMS.md task 1.
//
// Vision-judge call for production. The prompt, tool schema, and content
// blocks come from judgeRequest.ts, shared with the eval harness. Model
// strings live in models.ts.

import type { LLMJudgeFn, LLMJudgeInput, LLMJudgeOutput } from '../judge/types';
import { callAnthropic } from './anthropic';
import { rgbaToPngBase64 } from './imageEncode';
import { buildJudgeRequest, toLLMJudgeOutput, type JudgeResponse } from './judgeRequest';

export { JUDGE_MODEL } from './models';
export { JUDGE_SYSTEM_PROMPT, toLLMJudgeOutput } from './judgeRequest';

export type JudgePromptResponse = JudgeResponse;

const RENDER_SIZE = 512;

export const llmJudge: LLMJudgeFn = async (input: LLMJudgeInput): Promise<LLMJudgeOutput> => {
  const [userPngBase64, referencePngBase64] = await Promise.all([
    rgbaToPngBase64(input.userRender, RENDER_SIZE, RENDER_SIZE),
    rgbaToPngBase64(input.referenceRender, RENDER_SIZE, RENDER_SIZE),
  ]);

  const result = await callAnthropic<JudgePromptResponse>(
    buildJudgeRequest({
      challenge: input.challenge,
      userShaderSrc: input.userShaderSrc,
      userPngBase64,
      referencePngBase64,
    }),
  );

  return toLLMJudgeOutput(result.content);
};
