import { describe, expect, it } from 'vitest';
import { closestName, plainCompileError } from './compileHint';
import { describeDifference } from './diffReason';

describe('plainCompileError', () => {
  it('suggests the closest built-in for a misspelled function', () => {
    expect(plainCompileError("'lenght' : no matching overloaded function found", 12)).toBe(
      'Line 12: there is no function called lenght. Did you mean length?',
    );
  });

  it('suggests a uniform for a misspelled identifier', () => {
    expect(plainCompileError("'u_resolutoin' : undeclared identifier", 3)).toBe(
      "Line 3: u_resolutoin isn't defined. Did you mean u_resolution?",
    );
  });

  it('points WebGL 1 output at fragColor', () => {
    expect(plainCompileError("'gl_FragColor' : undeclared identifier", 9)).toMatch(
      /fragColor instead/,
    );
  });

  it('falls back to a generic line without a line number', () => {
    expect(plainCompileError('something unexpected')).toBe(
      "the shader didn't compile. The raw error is below.",
    );
  });

  it('does not suggest a name for an unrelated identifier', () => {
    expect(closestName('myShape')).toBeNull();
  });
});

// Square RGBA buffers, rows bottom-up like readPixels.
function disc(size: number, radius: number, cx = 0.5, cy = 0.5): Uint8Array {
  const px = new Uint8Array(size * size * 4);
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const i = (y * size + x) * 4;
      const inside = Math.hypot(x / size - cx, y / size - cy) < radius;
      px[i] = px[i + 1] = px[i + 2] = inside ? 255 : 0;
      px[i + 3] = 255;
    }
  }
  return px;
}

describe('describeDifference', () => {
  const S = 64;

  it('returns null for identical frames', () => {
    expect(describeDifference(disc(S, 0.3), disc(S, 0.3), S)).toBeNull();
  });

  it('says a smaller circle is smaller', () => {
    expect(describeDifference(disc(S, 0.2), disc(S, 0.3), S)).toBe(
      'Your shape comes out smaller than the reference. Check its size.',
    );
  });

  it('says a circle with a softer edge differs along the edges', () => {
    const soft = disc(S, 0.3);
    // Dim a 2px band just inside the edge, leaving the bright area the same.
    for (let y = 0; y < S; y++) {
      for (let x = 0; x < S; x++) {
        const r = Math.hypot(x / S - 0.5, y / S - 0.5);
        if (r < 0.3 && r > 0.3 - 2 / S) {
          const i = (y * S + x) * 4;
          soft[i] = soft[i + 1] = soft[i + 2] = 150;
        }
      }
    }
    expect(describeDifference(soft, disc(S, 0.3), S)).toBe(
      'Most of the difference sits along the edges of the shapes. Yours is darker there.',
    );
  });

  it('names the region of a misplaced blob', () => {
    // Reference is empty; yours has a blob at image top-left (high y in readPixels order).
    const empty = new Uint8Array(S * S * 4);
    expect(describeDifference(disc(S, 0.1, 0.2, 0.8), empty, S)).toBe(
      'Most of the difference sits toward the top-left. Yours is brighter there.',
    );
  });
});
