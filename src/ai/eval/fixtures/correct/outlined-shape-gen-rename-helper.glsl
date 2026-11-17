#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Rounded box: half-size (0.55, 0.35), corner radius 0.15
    vec2 corner = abs(p) - vec2(0.55, 0.35) + 0.15;
    float dist = length(max(corner, 0.0)) + min(max(corner.x, corner.y), 0.0) - 0.15;

    // abs() mirrors the inside onto the outside, so the shape becomes a stroke 0.04 either side of the edge
    float stroke = abs(dist) - 0.04;
    float ink = 1.0 - smoothstep(-0.01, 0.01, stroke);

    vec3 bg = vec3(0.05, 0.07, 0.15);
    vec3 fg = vec3(1.0, 0.8, 0.2);

    fragColor = vec4(mix(bg, fg, ink), 1.0);
}

void main() {
  shade();
}
