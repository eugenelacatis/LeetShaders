#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// @cell The fold
// @numbers p = abs(p) / dot(p, p) - c. That one line is the whole fold.
vec2 kaliFold(vec2 p, vec2 c) {
    return abs(p) / dot(p, p) - c;
}
// @end

// @cell Cosine palette
// @numbers a + b * cos(6.28318 * (c * t + trap)), with a = (0.5, 0.5, 0.5), b = (0.5, 0.5, 0.5), c = (1.0, 1.0, 1.0) and trap = (0.10, 0.20, 0.30).
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 trap = vec3(0.10, 0.20, 0.30);
    return a + b * cos(6.28318 * (c * t + trap));
}
// @end

// @cell Orbit trap glow
// @numbers 7 folds. After each, trap = min(abs(length(p) - 0.5), abs(p.y)): a ring of radius 0.5 joined with the x axis. Add palette(float(i) / 7.0) * exp(-24.0 * trap), i from 0.
vec3 kali(vec2 p, vec2 c) {
    vec3 glow = vec3(0.0);
    for (int i = 0; i < 7; i++) {
        p = kaliFold(p, c);
        float trap = min(abs(length(p) - 0.5), abs(p.y));
        glow += palette(float(i) / 7.0) * exp(-24.0 * trap);
    }
    return glow;
}
// @end

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // c drifts around a small circle once every 14 seconds, reshaping the fractal
    float a = 6.28318 * u_time / 14.0;
    vec2 c = vec2(0.62, 0.44) + 0.03 * vec2(cos(a), sin(a));

    vec3 glow = kali(uv * 1.2, c);

    // Tone map so overlapping glow doesn't clip to white
    glow = 1.0 - exp(-1.3 * glow);

    // Darken the corners
    glow *= 1.0 - 0.35 * dot(uv, uv) / 2.0;

    fragColor = vec4(glow, 1.0);
}

void main() {
  shade();
}
