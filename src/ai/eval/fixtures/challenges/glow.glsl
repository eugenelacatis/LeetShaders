#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to the disc's edge, radius 0.3
    float d = length(uv) - 0.3;

    // Glow: strongest at the edge, fading with exp(). max() keeps it from growing inside the disc
    float glow = exp(-5.0 * max(d, 0.0));

    vec3 bg = vec3(0.02, 0.02, 0.08);
    vec3 color = bg + vec3(1.0, 0.55, 0.15) * glow * 0.9;

    // White disc on top
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);
    color = mix(color, vec3(1.0), mask);

    fragColor = vec4(color, 1.0);
}
