# Challenge: Lava Lamp

The combining boss key: the last key on its board, using only that track's skills. It animates, so the judge's random `u_time` samples see it move.

## Intended Solution

```glsl
// Polynomial smooth minimum, blend width k
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Three blobs bob up and down on their own sine waves, so they meet and part
    float w = 6.28318;
    vec2 a = vec2(-0.30, 0.50 * sin(w * u_time / 10.0));
    vec2 b = vec2(0.28, 0.55 * sin(w * u_time / 8.0 + 2.0));
    vec2 c = vec2(0.00, 0.60 * sin(w * u_time / 12.0 + 4.0));

    float da = length(uv - a) - 0.26;
    float db = length(uv - b) - 0.22;
    float dc = length(uv - c) - 0.18;

    // Melt them together with a wide blend, so nearby blobs stretch into each other
    float d = smin(smin(da, db, 0.40), dc, 0.40);

    vec3 bg = vec3(0.16, 0.05, 0.22);
    vec3 orange = vec3(1.00, 0.42, 0.12);
    vec3 yellow = vec3(1.00, 0.85, 0.35);

    // Glow: an exp falloff outside the wax, added to the background
    vec3 color = bg + orange * 0.45 * exp(-8.0 * max(d, 0.0));

    // The wax: orange at the edge, yellow deeper inside
    vec3 wax = mix(orange, yellow, smoothstep(0.0, 0.15, -d));
    color = mix(color, wax, 1.0 - smoothstep(-0.008, 0.008, d));

    fragColor = vec4(color, 1.0);
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** blend width 0.3 or 0.5, glow falloff 6 or 10, a radius off by 0.02, or the yellow core starting deeper. A plain min() instead of smin() is a wrong (hard creases where the blobs touch).
- **Static-frame cheat:** the t = 0 frame with `u_time` removed matches the default sample only and must fail on MAE at the random samples.
- **Look-alikes:** Melting Pair (smooth-union) and Neon Halo (glow) are each one part of this, static and in other colours.
