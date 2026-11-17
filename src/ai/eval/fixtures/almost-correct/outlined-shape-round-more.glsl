#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Rounded box: half-size (0.55, 0.35), corner radius 0.15
    vec2 q = abs(uv) - vec2(0.55, 0.35) + 0.16;
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.16;

    // abs() mirrors the inside onto the outside, so the shape becomes a line 0.04 either side of the edge
    float line = abs(d) - 0.04;
    float mask = 1.0 - smoothstep(-0.01, 0.01, line);

    vec3 navy = vec3(0.05, 0.07, 0.15);
    vec3 gold = vec3(1.0, 0.8, 0.2);

    fragColor = vec4(mix(navy, gold, mask), 1.0);
}
