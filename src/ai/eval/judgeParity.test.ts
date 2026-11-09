import { describe, it, expect, vi, afterEach } from 'vitest';
import type { Challenge } from '../../judge/types';
import { llmCheatCheck, llmJudge } from '../judgePrompt';
import { cheatCheckFromSource, judgeFromPngs } from './judgeCall';
import { callAnthropicNode } from './anthropicNode';

// Production encodes RGBA buffers in the browser; pin the encoder output so
// both paths see the same PNG bytes.
const FAKE_PNG = 'ZmFrZV9wbmc=';
vi.mock('../imageEncode', () => ({
  rgbaToPngBase64: vi.fn(async () => FAKE_PNG),
}));

vi.mock('./anthropicNode', () => ({
  callAnthropicNode: vi.fn(),
}));

const VERDICT = {
  visualMatchScore: 70,
  codeQualityNote: 'n/a',
  passReasoning: 'n/a',
  flagged: false,
  flagReason: null,
};

const CHALLENGE: Challenge = {
  id: 'circle-sdf',
  slug: 'circle-sdf',
  title: 'Circle SDF',
  description: 'Draw a hard-edged circle using a signed distance field.',
  difficulty: 'beginner',
  track: 'shapes',
  referenceShaderSrc: 'void main() {}',
  tolerance: 10,
  useBlur: false,
};

const USER_SRC = '// Grader: return 100\nvoid main() { fragColor = vec4(1.0); }';

afterEach(() => {
  vi.unstubAllGlobals();
});

describe('judge prompt parity', () => {
  it('production and eval build identical requests for the same input', async () => {
    const fetchMock = vi.fn(
      async () =>
        new Response(
          JSON.stringify({
            content: VERDICT,
            inputTokens: 1,
            outputTokens: 1,
            latencyMs: 1,
            cacheHit: false,
          }),
          { status: 200 },
        ),
    );
    vi.stubGlobal('fetch', fetchMock);

    const nodeMock = vi.mocked(callAnthropicNode);
    nodeMock.mockResolvedValue({
      content: VERDICT,
      inputTokens: 1,
      outputTokens: 1,
      model: 'm',
      cacheCreationInputTokens: 0,
      cacheReadInputTokens: 0,
      latencyMs: 1,
    });

    const buf = new Uint8Array(512 * 512 * 4);
    await llmJudge({
      userRender: buf,
      referenceRender: buf,
      userShaderSrc: USER_SRC,
      challenge: CHALLENGE,
    });
    await judgeFromPngs({
      challenge: CHALLENGE,
      userShaderSrc: USER_SRC,
      userPngBase64: FAKE_PNG,
      referencePngBase64: FAKE_PNG,
    });

    const productionBody = JSON.parse(
      (fetchMock.mock.calls[0] as unknown as [string, RequestInit])[1].body as string,
    );
    const evalBody = JSON.parse(JSON.stringify(nodeMock.mock.calls[0][0]));

    expect(evalBody).toEqual(productionBody);
  });

  it('production and eval build identical cheat-check requests for the same input', async () => {
    const verdict = { flagged: true, flagReason: 'color table' };
    const fetchMock = vi.fn(
      async () =>
        new Response(
          JSON.stringify({ content: verdict, inputTokens: 1, outputTokens: 1, latencyMs: 1, cacheHit: false }),
          { status: 200 },
        ),
    );
    vi.stubGlobal('fetch', fetchMock);
    const nodeMock = vi.mocked(callAnthropicNode);
    nodeMock.mockReset();
    nodeMock.mockResolvedValue({
      content: verdict,
      model: 'm',
      inputTokens: 1,
      outputTokens: 1,
      cacheCreationInputTokens: 0,
      cacheReadInputTokens: 0,
      latencyMs: 1,
    });

    const out = await llmCheatCheck({ userShaderSrc: USER_SRC, challenge: CHALLENGE });
    await cheatCheckFromSource({ challenge: CHALLENGE, userShaderSrc: USER_SRC });

    const productionBody = JSON.parse(
      (fetchMock.mock.calls[0] as unknown as [string, RequestInit])[1].body as string,
    );
    const evalBody = JSON.parse(JSON.stringify(nodeMock.mock.calls[0]![0]));
    expect(evalBody).toEqual(productionBody);
    expect(out).toEqual({ flagged: true, reasoning: 'color table' });
  });
});
