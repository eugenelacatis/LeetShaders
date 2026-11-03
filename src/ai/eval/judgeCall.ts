// AI Systems & Integration. Node-side LLM-judge call for the eval
// harness. Builds the exact request production sends (judgeRequest.ts)
// and sends it through the SDK directly, because this runs under tsx
// rather than behind the browser proxy.

import { callAnthropicNode } from './anthropicNode';
import {
  buildJudgeRequest,
  type BuildJudgeRequestInput,
  type JudgeResponse,
} from '../judgeRequest';

export type { JudgeResponse } from '../judgeRequest';

export interface JudgeCallResult {
  response: JudgeResponse;
  inputTokens: number;
  outputTokens: number;
  cacheCreationInputTokens: number;
  cacheReadInputTokens: number;
  latencyMs: number;
}

export async function judgeFromPngs(input: BuildJudgeRequestInput): Promise<JudgeCallResult> {
  const result = await callAnthropicNode<JudgeResponse>(buildJudgeRequest(input));
  return {
    response: result.content,
    inputTokens: result.inputTokens,
    outputTokens: result.outputTokens,
    cacheCreationInputTokens: result.cacheCreationInputTokens,
    cacheReadInputTokens: result.cacheReadInputTokens,
    latencyMs: result.latencyMs,
  };
}
