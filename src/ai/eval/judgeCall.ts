// AI Systems & Integration. Node-side LLM-judge call for the eval
// harness. Builds the exact request production sends (judgeRequest.ts)
// and sends it through the SDK directly, because this runs under tsx
// rather than behind the browser proxy.

import { callAnthropicNode } from './anthropicNode';
import {
  buildCheatCheckRequest,
  buildJudgeRequest,
  type BuildCheatCheckRequestInput,
  type BuildJudgeRequestInput,
  type CheatCheckResponse,
  type JudgeResponse,
} from '../judgeRequest';

export type { CheatCheckResponse, JudgeResponse } from '../judgeRequest';

export interface CallUsage {
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheCreationInputTokens: number;
  cacheReadInputTokens: number;
  latencyMs: number;
}

export interface JudgeCallResult extends CallUsage {
  response: JudgeResponse;
}

export interface CheatCheckCallResult extends CallUsage {
  response: CheatCheckResponse;
}

export async function judgeFromPngs(input: BuildJudgeRequestInput): Promise<JudgeCallResult> {
  const { content, ...usage } = await callAnthropicNode<JudgeResponse>(buildJudgeRequest(input));
  return { response: content, ...usage };
}

export async function cheatCheckFromSource(input: BuildCheatCheckRequestInput): Promise<CheatCheckCallResult> {
  const { content, ...usage } = await callAnthropicNode<CheatCheckResponse>(buildCheatCheckRequest(input));
  return { response: content, ...usage };
}
