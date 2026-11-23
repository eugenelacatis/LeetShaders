# Challenge: Mandelbulb

A capstone mixing combining (subtraction with `max(a, -b)`) and raymarching (a fractal distance estimator). The starter in `mandelbulb.starter.glsl` locks the spin and tilt, the camera, the bounding-sphere march, the tetrahedron normal, ambient occlusion, colors and light. The learner fills three cells. The reference is the starter with the cells solved; the locked code must match (`src/challenges/capstones.test.ts`).

## Intended Solution

```glsl
// @cell Triplex power
vec3 triplexPow8(vec3 z) {
    float r = length(z);
    float theta = 8.0 * acos(clamp(z.y / r, -1.0, 1.0));
    float phi = 8.0 * atan(z.z, z.x);
    return pow(r, 8.0) * vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
}

// @cell Distance estimator
float mandelbulb(vec3 c) {
    vec3 z = c;
    float dr = 1.0;
    float r = length(z);
    for (int i = 0; i < 6; i++) {
        if (r > 2.0) break;
        dr = 8.0 * pow(r, 7.0) * dr + 1.0;
        z = triplexPow8(z) + c;
        r = length(z);
    }
    return 0.5 * log(r) * r / dr;
}

// @cell Cutaway
float scene(vec3 p) {
    float bulb = mandelbulb(spin * p);
    float cut = length(p - vec3(0.45, 0.5, 0.75)) - 0.55;
    return max(bulb, -cut);
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code. The power-8 triplex formula and the `0.5 * log(r) * r / dr` estimator are the widely published White / Nylander forms; no shader was copied. The bulb's axis is y here (theta from y), not the usual z.
- **Starter:** the estimator cell returns `length(c) - 1.0`, so the starter shows a lit sphere. The other two cells return `z` and `mandelbulb(p)`.
- **Cost:** SwiftShader at 512x512, 145 to 210ms warm (about 470ms cold). Apple M1 (Metal) 10 to 14ms warm. Byte-identical on repeat. Caps: 64 march steps inside a bounding sphere of radius 1.25, 6 iterations, 4 normal samples, 5 AO samples.
- **Cross-GPU:** SwiftShader vs Apple M1 Metal, raw MAE 0.122 at t = 0, 0.428 at t = 23, 0.258 at t = 37, 0.424 at t = 58 (blurred 0.083 to 0.220). The highest in the bank, since `acos`, `atan` and `pow` differ by GPU, but far below the raymarching tolerances (about 6).
- **Animation:** `spin = tilt * turn`: a turn about y once every 18 s, then a 0.4 radian tilt about x, all locked. The power-8 bulb has 7-fold symmetry about its own axis, so an untilted turn repeated every 18 / 7 s (t = 3 looked like t = 0). With the tilt, the static-frame cheat (`u_time` removed) scores raw 16.5 to 17.7 at t = 1, 2.571, 3, 6, 15, 30, 45 and 59. t = 0 vs t = 58 raw 17.3.
- **Rewrites that pass:** no `clamp` in `acos` (raw 0.000), `r^8` written as a product (0.001), the common loop that computes `r` at the top and returns that stale `r` (0.169 / 0.258 at t = 0 / 37).
- **Near misses:** 5 or 7 iterations (0.17 to 0.46, inside cross-GPU noise, so MAE can't tell them from the reference), bailout 4.0 (0.03), cut radius 0.50 (2.3). **Wrongs:** no `spin` in the cutaway (17.5), the usual z-axis triplex (17.6), `min(bulb, cut)` union instead of the cut (22.7); also expected to fail: the estimator left as the TODO sphere, the cutaway left as `mandelbulb(p)`, the locked camera or spin edited.
- **Look-alikes:** `raymarched-sphere` (the starter's sphere), `subtraction` (2D cut), `the-full-scene`.
