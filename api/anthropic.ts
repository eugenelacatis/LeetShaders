// Vercel serverless proxy for Anthropic API calls.
// CJS only — no import statements. "type":"module" in root package.json is
// overridden by api/package.json {"type":"commonjs"}.

/* eslint-disable @typescript-eslint/no-require-imports */
const Anthropic = require('@anthropic-ai/sdk');

interface TextContent { type: 'text'; text: string; cacheControl?: 'ephemeral' }
interface ImageContent { type: 'image'; mediaType: string; base64: string; cacheControl?: 'ephemeral' }
type ContentBlock = TextContent | ImageContent;
interface JsonOutputSchema { name: string; schema: Record<string, unknown> }
interface AnthropicCallInput {
  model: string; system: string; userContent: ContentBlock[];
  maxTokens: number; effort?: 'low' | 'medium' | 'high'; jsonSchema?: JsonOutputSchema;
}
interface AnthropicCallOutput {
  content: unknown; inputTokens: number; outputTokens: number;
  latencyMs: number; cacheHit: boolean;
}

// Models with server-side refusal fallback (src/ai/models.ts
// supportsRefusalFallback). Haiku 5.5 has none. Keep the request translation
// below in step with src/ai/eval/anthropicNode.ts.
const FALLBACK_MODELS = new Set(['claude-opus-5-5', 'claude-sonnet-5-5']);
const FALLBACK_BETA = 'server-side-fallback-2026-07-01';

// Minimal shapes for what this handler touches. The file stays CJS with no
// imports, so it can't pull in node:http or SDK types.
interface Req {
  method?: string;
  body?: AnthropicCallInput;
  on(event: 'data' | 'end' | 'error', listener: (arg?: Buffer | Error) => void): void;
}
interface Res {
  writeHead(status: number, headers: Record<string, string>): void;
  end(body: string): void;
}
interface ApiMessage {
  stop_reason: string | null;
  content: { type: string; text?: string }[];
  usage: { input_tokens: number; output_tokens: number; cache_read_input_tokens?: number | null };
}

function send(res: Res, status: number, body: unknown) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

function readBody(req: Req): Promise<AnthropicCallInput> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    req.on('data', (c) => chunks.push(c as Buffer));
    req.on('end', () => {
      try { resolve(JSON.parse(Buffer.concat(chunks).toString())); }
      catch { reject(new Error('bad json')); }
    });
    req.on('error', reject);
  });
}

function toBlock(block: ContentBlock): unknown {
  const cache = block.cacheControl === 'ephemeral' ? { type: 'ephemeral' } : undefined;
  if (block.type === 'text') {
    return cache ? { type: 'text', text: block.text, cache_control: cache }
                 : { type: 'text', text: block.text };
  }
  const source = { type: 'base64', media_type: block.mediaType, data: block.base64 };
  return cache ? { type: 'image', source, cache_control: cache } : { type: 'image', source };
}

module.exports = async function handler(req: Req, res: Res) {
  if (req.method !== 'POST') return send(res, 405, { error: 'Method not allowed' });

  const apiKey = process.env.ANTHROPIC_API_KEY;
  if (!apiKey) return send(res, 500, { error: 'ANTHROPIC_API_KEY is not configured' });

  let body: AnthropicCallInput;
  try {
    body = req.body ?? await readBody(req);
  } catch {
    return send(res, 400, { error: 'Invalid JSON body' });
  }

  if (!body?.model || !body?.userContent || !body?.maxTokens)
    return send(res, 400, { error: 'Invalid request body' });

  const client = new Anthropic({ apiKey });
  const start = Date.now();

  const params: Record<string, unknown> = {
    model: body.model,
    system: body.system,
    max_tokens: body.maxTokens,
    messages: [{ role: 'user', content: body.userContent.map(toBlock) }],
  };

  // These models reject a forced tool_choice, so JSON comes from structured
  // outputs. Thinking is always on; effort sets how much.
  if (body.effort || body.jsonSchema) {
    params.output_config = {
      ...(body.effort ? { effort: body.effort } : {}),
      ...(body.jsonSchema ? { format: { type: 'json_schema', schema: body.jsonSchema.schema } } : {}),
    };
  }
  const fallback = FALLBACK_MODELS.has(body.model);
  if (fallback) params.fallbacks = 'default';

  let message: ApiMessage;
  try {
    message = await client.messages.create(
      params,
      fallback ? { headers: { 'anthropic-beta': FALLBACK_BETA } } : undefined,
    );
  } catch (err) {
    const e = err as { status?: number; message?: string };
    return send(res, e.status ?? 502, { error: e.message ?? 'Anthropic request failed' });
  }
  const latencyMs = Date.now() - start;

  if (message.stop_reason === 'refusal') return send(res, 422, { error: `${body.model} declined the request` });
  if (message.stop_reason === 'max_tokens') return send(res, 502, { error: `${body.model} hit max_tokens before finishing` });

  // Responses can start with thinking blocks; read the text block by type.
  const text: string = message.content.find((b) => b.type === 'text')?.text ?? '';
  let content: unknown = text;
  if (body.jsonSchema) {
    try { content = JSON.parse(text); }
    catch { return send(res, 502, { error: 'Model returned invalid JSON' }); }
  }

  const usage = message.usage;
  const output: AnthropicCallOutput = {
    content,
    inputTokens: usage.input_tokens,
    outputTokens: usage.output_tokens,
    latencyMs,
    cacheHit: (usage.cache_read_input_tokens ?? 0) > 0,
  };

  return send(res, 200, output);
};
