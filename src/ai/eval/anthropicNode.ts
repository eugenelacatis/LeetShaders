// AI Systems & Integration. Node-side Anthropic call for the eval
// harness. Mirrors api/anthropic.ts (the production proxy) but runs under
// tsx with the SDK directly.
//
// This file holds ANTHROPIC_API_KEY, so keep it behind the eval folder and
// never import src/ai/anthropic.ts here (that one is typed against lib.dom).
//
// Keep the request translation (structured output, effort, refusal
// fallback, refusal handling) in step with api/anthropic.ts.

import Anthropic from '@anthropic-ai/sdk';

import { supportsRefusalFallback, type AnthropicModel, type Effort } from '../models';

export { JUDGE_MODEL, HINT_MODEL, CHEAT_CHECK_MODEL, type AnthropicModel } from '../models';

export interface TextBlock {
  type: 'text';
  text: string;
  cacheControl?: 'ephemeral';
}

export interface ImageBlock {
  type: 'image';
  mediaType: 'image/png' | 'image/jpeg';
  base64: string;
  cacheControl?: 'ephemeral';
}

export type ContentBlock = TextBlock | ImageBlock;

export interface JsonOutputSchema {
  name: string;
  schema: Record<string, unknown>;
}

export interface CallInput {
  model: AnthropicModel;
  system: string;
  userContent: ContentBlock[];
  maxTokens: number;
  effort?: Effort;
  /** When set, the reply is JSON matching this schema (structured outputs). */
  jsonSchema?: JsonOutputSchema;
}

export interface CallOutput<T = string> {
  content: T;
  /** The model that answered; differs from the request after a refusal fallback. */
  model: string;
  inputTokens: number;
  outputTokens: number;
  cacheCreationInputTokens: number;
  cacheReadInputTokens: number;
  latencyMs: number;
}

export class ModelRefusalError extends Error {}

// SDK 0.32 predates these request fields and response fields; the API
// accepts and returns them regardless.
type CreateParams = Anthropic.Messages.MessageCreateParamsNonStreaming & {
  output_config?: {
    effort?: Effort;
    format?: { type: 'json_schema'; schema: Record<string, unknown> };
  };
  fallbacks?: 'default';
};

type UsageWithCache = Anthropic.Messages.Usage & {
  cache_creation_input_tokens?: number | null;
  cache_read_input_tokens?: number | null;
};

const FALLBACK_BETA = 'server-side-fallback-2026-07-01';

function getClient(): Anthropic {
  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) {
    throw new Error('ANTHROPIC_API_KEY not set. Add it to .env.local or export it.');
  }
  return new Anthropic({ apiKey });
}

function toSdkContent(
  block: ContentBlock,
): Anthropic.Messages.TextBlockParam | Anthropic.Messages.ImageBlockParam {
  // Forward cache markers the same way api/anthropic.ts does, so eval
  // token costs match production.
  const cache =
    block.cacheControl === 'ephemeral' ? { cache_control: { type: 'ephemeral' as const } } : {};
  if (block.type === 'text') {
    return { type: 'text', text: block.text, ...cache };
  }
  return {
    type: 'image',
    source: { type: 'base64', media_type: block.mediaType, data: block.base64 },
    ...cache,
  };
}

/**
 * Invoke Claude. Returns parsed JSON when `jsonSchema` is set, otherwise
 * the text of the reply. Throws ModelRefusalError on a refusal and a plain
 * Error when the reply is cut off by max_tokens.
 */
export async function callAnthropicNode<T = string>(input: CallInput): Promise<CallOutput<T>> {
  const client = getClient();
  const start = performance.now();

  const params: CreateParams = {
    model: input.model,
    max_tokens: input.maxTokens,
    system: input.system,
    messages: [{ role: 'user', content: input.userContent.map(toSdkContent) }],
  };
  if (input.effort || input.jsonSchema) {
    params.output_config = {
      ...(input.effort ? { effort: input.effort } : {}),
      ...(input.jsonSchema
        ? { format: { type: 'json_schema', schema: input.jsonSchema.schema } }
        : {}),
    };
  }
  const fallback = supportsRefusalFallback(input.model);
  if (fallback) params.fallbacks = 'default';

  const message = await client.messages.create(
    params,
    fallback ? { headers: { 'anthropic-beta': FALLBACK_BETA } } : undefined,
  );
  const latencyMs = performance.now() - start;

  const stopReason = message.stop_reason as string | null;
  if (stopReason === 'refusal') {
    throw new ModelRefusalError(`${input.model} declined the request`);
  }
  if (stopReason === 'max_tokens') {
    throw new Error(`${input.model} hit max_tokens (${input.maxTokens}) before finishing`);
  }

  // Responses can start with thinking blocks; read the text block by type.
  const text = message.content.find((b) => b.type === 'text');
  if (!text || text.type !== 'text') throw new Error('expected a text block in the response');
  const content = (input.jsonSchema ? JSON.parse(text.text) : text.text) as T;

  const usage = message.usage as UsageWithCache;
  return {
    content,
    model: message.model,
    inputTokens: usage.input_tokens,
    outputTokens: usage.output_tokens,
    cacheCreationInputTokens: usage.cache_creation_input_tokens ?? 0,
    cacheReadInputTokens: usage.cache_read_input_tokens ?? 0,
    latencyMs,
  };
}
