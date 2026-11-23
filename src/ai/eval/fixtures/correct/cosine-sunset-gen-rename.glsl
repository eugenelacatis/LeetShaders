#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

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
    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // The skyColor: the palette read by height, and it never moves
    vec3 skyColor = palette(0.30 + 0.25 * st.y);

    // The rings sits low at (0, -0.6). Its rings read the palette by distance,
    // and subtracting time / 8 makes them flow outward, one full cycle every 8 seconds
    float dist = length(st - vec2(0.0, -0.6));
    vec3 rings = palette(2.0 * dist - u_time / 8.0);

    // Rings near the rings, skyColor farther out
    vec3 col = mix(rings, skyColor, smoothstep(0.35, 0.75, dist));

    fragColor = vec4(col, 1.0);
}
