# Challenge: Kali Fractal

A capstone mixing color (cosine palette) and combining (a union of two SDFs used as an orbit trap, plus glow). The fold `abs(p) / dot(p, p) - c` is Kali's (Pablo Roman Andrioli's Kaliset); the code here is our own. The starter in `kali-fractal.starter.glsl` locks c and its drift, the 1.2 zoom, the tone map and the corner darkening. The learner fills three cells. The reference is the starter with the cells solved; the locked code must match (`src/challenges/capstones.test.ts`).

## Intended Solution

```glsl
// @cell The fold
vec2 kaliFold(vec2 p, vec2 c) {
    return abs(p) / dot(p, p) - c;
}

// @cell Cosine palette
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.10, 0.20, 0.30);
    return a + b * cos(6.28318 * (c * t + d));
}

// @cell Orbit trap glow
vec3 kali(vec2 p, vec2 c) {
    vec3 color = vec3(0.0);
    for (int i = 0; i < 7; i++) {
        p = kaliFold(p, c);
        float d = min(abs(length(p) - 0.5), abs(p.y));
        color += palette(float(i) / 7.0) * exp(-24.0 * d);
    }
    return color;
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code. The fold formula is Kali's, widely published; no shader was copied.
- **Cost:** SwiftShader at 512x512, 31 to 82ms warm (about 260ms cold). Apple M1 (Metal) 3 to 7ms warm. Byte-identical on repeat.
- **Cross-GPU:** SwiftShader vs Apple M1 Metal, raw MAE 0.002 at t = 0, 0.008 at t = 23 and t = 37, 0.009 at t = 58 (blurred the same). The fractal is chaotic, but seven folds keep float error small.
- **Rewrites:** `abs(p) * (1.0 / dot(p, p)) - c` and `p = abs(p); p / (p.x * p.x + p.y * p.y) - c` both score raw 0.000 against the reference at t = 0 and 37, so equivalent algebra passes.
- **Fold count:** 9 folds gave a noisy, grain-like frame; 7 shows the structure. A sharper glow (`exp(-40 d)`) went too dark.
- **Animation:** c = (0.62, 0.44) + 0.03 * (cos, sin)(2 pi t / 14), locked. 14 s doesn't divide 30 or 37, so t = 0 and t = 30 differ; t = 0 vs t = 58 raw 42.9. Don't animate by rotating the view: `abs()` gives the frame 4-fold symmetry, so a rotation repeats every quarter turn. The static-frame cheat (t = 0 frame, `u_time` removed) should fail at the random samples.
- **Near misses:** glow 22 or 26; ring radius 0.48 or 0.52; palette d nudged by 0.02; i / 7 replaced with (i + 0.5) / 7. **Wrongs:** 6 or 8 folds (the shape changes a lot); trap with only the ring or only the axis; `max` instead of `min` (intersection); `dot(p, p)` replaced with `length(p)`; no `abs` (no mirror symmetry); palette left as the TODO; the locked c edited.
- **Look-alikes:** `kaleidoscope` (mirror symmetry, gold on navy), `glow`, `cosine-sunset` (same palette formula, different d).
