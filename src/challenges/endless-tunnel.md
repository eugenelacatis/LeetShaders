# Challenge: Endless Tunnel

A capstone mixing color (cosine palette) and patterns (polar coordinates, staggered tiles). The starter in `endless-tunnel.starter.glsl` locks the forward motion (0.5 depth units a second), the per-row palette input `0.07 * row`, the grout color, the overhead light and the glow at the far end. The learner fills three cells. The reference is the starter with the cells solved; the locked code must match (`src/challenges/capstones.test.ts`).

## Intended Solution

```glsl
// @cell Tunnel coordinates
vec2 tunnel(vec2 uv) {
    float angle = atan(uv.y, uv.x) / 6.28318 + 0.5;
    float depth = 0.35 / length(uv);
    return vec2(angle, depth);
}

// @cell Wall tiles
vec2 tiles(vec2 tc) {
    vec2 q = tc * vec2(24.0, 4.0);
    float row = floor(q.y);
    q.x += 0.5 * mod(row, 2.0);
    vec2 f = fract(q) - 0.5;
    vec2 b = abs(f) - vec2(0.38 - 0.1);
    float d = length(max(b, 0.0)) + min(max(b.x, b.y), 0.0) - 0.1;
    return vec2(1.0 - smoothstep(-0.03, 0.03, d), row);
}

// @cell Cosine palette
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Cost:** SwiftShader at 512x512, 28 to 43ms warm (about 245ms cold). Apple M1 (Metal) 2 to 5ms warm. Byte-identical on repeat.
- **Cross-GPU:** SwiftShader vs Apple M1 Metal, raw MAE 0.002 at t = 0, 0.004 at t = 23, 0.001 at t = 37, 0.003 at t = 58 (blurred the same).
- **Animation:** the walls move 0.5 depth units (2 rows) a second, locked. The tile layout repeats every 2 rows (1 s), but the palette input `0.07 * row` doesn't, so no two sample times match: t = 0 vs t = 37 raw 32.6. The static-frame cheat (t = 0 frame, `u_time` removed) should fail at the random samples.
- **Seam:** the angle runs 0 to 1 and the tile count around is a whole number (24), so the tiles meet cleanly where `atan` wraps. A fractional count leaves a seam on the left.
- **Moire:** rows shrink toward the center and alias below about 3 px; the glow (`1 - exp(-0.3 * depth)`) covers that region.
- **Near misses:** radius 0.33 or 0.37; tile half-size 0.36 or 0.40; corner 0.08 or 0.12; edge width 0.02 or 0.04; palette d nudged by 0.02. **Wrongs:** no stagger; 16 or 32 tiles around; depth = length(uv) (inside-out); angle in radians without dividing by 2 pi (seam, 6x tiles); palette left as the TODO (grey rows); the `cosine-sunset` palette; the locked speed edited.
- **Look-alikes:** `cosine-sunset` (same palette formula, different d and no tunnel), `polar-pattern`, `kaleidoscope`, `bricks` (the flat version of the tile cell).
