import { describe, it, expect, vi } from 'vitest';
import {
  DEFAULT_BANDS,
  applyBandLogic,
  classifyByBand,
  combineScores,
} from './bandLogic';

describe('classifyByBand', () => {
  it('returns confident-pass at and above upperBand', () => {
    expect(classifyByBand(70).kind).toBe('confident-pass');
    expect(classifyByBand(100).kind).toBe('confident-pass');
  });

  it('returns confident-fail strictly below lowerBand', () => {
    expect(classifyByBand(0).kind).toBe('confident-fail');
    expect(classifyByBand(59.9).kind).toBe('confident-fail');
  });

  it('returns needs-llm in the borderline band', () => {
    expect(classifyByBand(60).kind).toBe('needs-llm');
    expect(classifyByBand(69.9).kind).toBe('needs-llm');
  });
});

describe('combineScores', () => {
  it('weights mae and llm with the configured coefficients', () => {
    expect(combineScores(80, 60)).toBe(70);
  });

  it('clamps to [0, 100]', () => {
    const cfg = { ...DEFAULT_BANDS, maeWeight: 10, llmWeight: 10 };
    expect(combineScores(50, 50, cfg)).toBe(100);
  });
});

describe('applyBandLogic', () => {
  it('skips the LLM when MAE is confidently pass', async () => {
    const callLLM = vi.fn();
    const result = await applyBandLogic({ maeScore: 95, callLLM });
    expect(result.llmInvoked).toBe(false);
    expect(result.passed).toBe(true);
    expect(callLLM).not.toHaveBeenCalled();
  });

  it('skips the LLM when MAE is confidently fail', async () => {
    const callLLM = vi.fn();
    const result = await applyBandLogic({ maeScore: 10, callLLM });
    expect(result.llmInvoked).toBe(false);
    expect(result.passed).toBe(false);
    expect(callLLM).not.toHaveBeenCalled();
  });

  it('invokes the LLM and combines scores in the borderline band', async () => {
    const callLLM = vi.fn(async () => ({ score: 95, reasoning: 'close', flagged: false }));
    const result = await applyBandLogic({ maeScore: 65, callLLM });
    expect(result.llmInvoked).toBe(true);
    expect(result.finalScore).toBe(80);
    expect(result.passed).toBe(true);
    expect(callLLM).toHaveBeenCalledOnce();
  });

  it('forces fail when the LLM flags the shader for cheating', async () => {
    const callLLM = vi.fn(async () => ({
      score: 100,
      reasoning: 'samples reference texture directly',
      flagged: true,
    }));
    const result = await applyBandLogic({ maeScore: 65, callLLM });
    expect(result.passed).toBe(false);
    expect(result.finalScore).toBe(0);
    expect(result.trace).toMatch(/Flagged/);
  });
});

describe('applyBandLogic cheat check', () => {
  const clean = { flagged: false, reasoning: '' };

  it('runs the cheat check on a confident pass and keeps the pass when clean', async () => {
    const callLLM = vi.fn();
    const callCheatCheck = vi.fn(async () => clean);
    const result = await applyBandLogic({ maeScore: 99, callLLM, callCheatCheck });
    expect(callCheatCheck).toHaveBeenCalledOnce();
    expect(callLLM).not.toHaveBeenCalled();
    expect(result.passed).toBe(true);
    expect(result.cheatCheck).toEqual(clean);
  });

  it('fails a confident pass the cheat check flags', async () => {
    const callCheatCheck = vi.fn(async () => ({ flagged: true, reasoning: 'baked color table' }));
    const result = await applyBandLogic({ maeScore: 99, callLLM: vi.fn(), callCheatCheck });
    expect(result.passed).toBe(false);
    expect(result.finalScore).toBe(0);
    expect(result.trace).toMatch(/baked color table/);
  });

  it('keeps the MAE pass when the cheat check errors', async () => {
    const callCheatCheck = vi.fn(async () => {
      throw new Error('timeout');
    });
    const result = await applyBandLogic({ maeScore: 99, callLLM: vi.fn(), callCheatCheck });
    expect(result.passed).toBe(true);
    expect(result.cheatCheck).toBeNull();
    expect(result.trace).toMatch(/Cheat check unavailable/);
  });

  it('does not run the cheat check on borderline or confident-fail scores', async () => {
    const callCheatCheck = vi.fn(async () => clean);
    const callLLM = vi.fn(async () => ({ score: 50, reasoning: '', flagged: false }));
    await applyBandLogic({ maeScore: 65, callLLM, callCheatCheck });
    await applyBandLogic({ maeScore: 10, callLLM, callCheatCheck });
    expect(callCheatCheck).not.toHaveBeenCalled();
  });
});

