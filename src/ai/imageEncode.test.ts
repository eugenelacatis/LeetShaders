import { describe, it, expect } from 'vitest';
import { flipRowsToTopDown } from './imageEncode';

describe('flipRowsToTopDown', () => {
  it('reverses row order so the GL bottom row becomes the first image row', () => {
    // 2x3 image, one byte value per row: bottom row (readPixels row 0) = 10.
    const w = 2;
    const h = 3;
    const rgba = new Uint8Array(w * h * 4);
    for (let y = 0; y < h; y++) rgba.fill(10 * (y + 1), y * w * 4, (y + 1) * w * 4);

    const out = flipRowsToTopDown(rgba, w, h);

    expect(out[0]).toBe(30); // top image row = top of the render
    expect(out[w * 4]).toBe(20);
    expect(out[2 * w * 4]).toBe(10); // last image row = GL row 0
    expect(out.length).toBe(rgba.length);
  });

  it('keeps pixels within a row in order', () => {
    const rgba = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]); // 2x1
    expect(Array.from(flipRowsToTopDown(rgba, 2, 1))).toEqual([1, 2, 3, 4, 5, 6, 7, 8]);
  });
});
