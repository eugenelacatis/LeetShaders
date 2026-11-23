# Challenge: Cosine Sunset

The color boss key: the last key on its board, using only that track's skills. It animates, so the judge's random `u_time` samples see it move.

## Intended Solution

```glsl
// Cosine palette: a + b * cos(2 pi * (c * t + d)). Four vec3s give a whole
// gradient, and because cos repeats, t can grow forever
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.10, 0.20);
    return a + b * cos(6.28318 * (c * t + d));
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // The sky: the palette read by height, and it never moves
    vec3 sky = palette(0.30 + 0.25 * uv.y);

    // The sun sits low at (0, -0.6). Its rings read the palette by distance,
    // and subtracting time / 8 makes them flow outward, one full cycle every 8 seconds
    float r = length(uv - vec2(0.0, -0.6));
    vec3 sun = palette(2.0 * r - u_time / 8.0);

    // Rings near the sun, sky farther out
    vec3 color = mix(sun, sky, smoothstep(0.35, 0.75, r));

    fragColor = vec4(color, 1.0);
}
```

## Calibration Notes
- **Tolerance:** provisional `50`. Run `npx tsx src/ai/eval/run.ts --mae-only --set=tuning` once fixtures exist and replace it.
- **Source:** own code.
- **Near misses:** a wrong d vector (shifts every hue), 1.2 or 2.5 rings per unit instead of 2.0, the sun at (0, -0.5), or the blend edges moved. Adding time instead of subtracting it runs the rings inward and matches only at t = 0 and whole periods.
- **Static-frame cheat:** the t = 0 frame with `u_time` removed matches the default sample only and must fail on MAE at the random samples.
- **Look-alikes:** Golden Hour is a static three-stop gradient with different colours, so its reference must score as a wrong.
