import { describe, it, expect, vi } from 'vitest';

// No WebGL in Node: fake the pipeline so "renders" depend on the uniforms.
vi.mock('../pipeline', () => ({
  CANVAS_SIZE: 512,
  WATCHDOG_MS: 2000,
  compileAndRender: vi.fn(),
  compileShader: vi.fn(),
  render: vi.fn(),
  getContext: vi.fn(),
  getCanvas: vi.fn(),
}));

import { mulberry32, sampleUniforms } from '../uniforms';
import { judge } from '../combiner';
import { compileAndRender, type Uniforms } from '../pipeline';
import type { Challenge, LLMJudgeFn } from '../types';

const BUF_SIZE = 512 * 512 * 4;
function solid(v: number): Uint8Array {
  const buf = new Uint8Array(BUF_SIZE);
  for (let i = 0; i < BUF_SIZE; i += 4) {
    buf[i] = v; buf[i + 1] = v; buf[i + 2] = v; buf[i + 3] = 255;
  }
  return buf;
}
const REF = solid(200);
const WRONG = solid(0);

const REFERENCE_SRC = 'reference';
const TIME_BRANCH_SRC = 'if (u_time == 0.0) { reference } else { wrong }';

const CHALLENGE: Challenge = {
  id: 'c', slug: 'c', title: 'C', description: '', difficulty: 'beginner', track: 'shapes',
  referenceShaderSrc: REFERENCE_SRC, tolerance: 10, useBlur: false,
};

vi.mocked(compileAndRender).mockImplementation((src: string, uniforms: Uniforms = {}) => {
  const t = uniforms.u_time ?? 0;
  const pixels = src === TIME_BRANCH_SRC && t !== 0 ? WRONG : REF;
  return { pixels, compileMs: 0, renderMs: 0 };
});

const neverLLM: LLMJudgeFn = async () => {
  throw new Error('LLM should not be called');
};

describe('mulberry32 / sampleUniforms', () => {
  it('is deterministic for a given seed', () => {
    const a = mulberry32(1337);
    const b = mulberry32(1337);
    for (let i = 0; i < 100; i++) expect(a()).toBe(b());
    expect(sampleUniforms(1337)).toEqual(sampleUniforms(1337));
  });

  it('differs across seeds and stays in range', () => {
    expect(sampleUniforms(1)).not.toEqual(sampleUniforms(2));
    for (const s of sampleUniforms(42, 50).slice(1)) {
      expect(s.u_time).toBeGreaterThanOrEqual(0);
      expect(s.u_time).toBeLessThan(60);
      expect(s.u_mouse![0]).toBeLessThanOrEqual(512);
    }
  });

  it('keeps the default inputs as sample 0', () => {
    expect(sampleUniforms(7)[0]).toEqual({});
    expect(sampleUniforms(7)).toHaveLength(4);
  });
});

describe('judge with uniform samples', () => {
  it('fails a shader that only matches the reference at u_time == 0', async () => {
    const result = await judge(TIME_BRANCH_SRC, CHALLENGE, neverLLM, undefined, sampleUniforms(1337));
    expect(result.passed).toBe(false);
    expect(result.maeScore).toBe(0);
  });

  it('the same cheat passes with only the default sample (why sampling matters)', async () => {
    const result = await judge(TIME_BRANCH_SRC, CHALLENGE, neverLLM);
    expect(result.passed).toBe(true);
  });

  it('still passes a correct shader at every sample', async () => {
    const result = await judge(REFERENCE_SRC, CHALLENGE, neverLLM, undefined, sampleUniforms(1337));
    expect(result.passed).toBe(true);
    expect(result.maeScore).toBe(100);
  });
});
