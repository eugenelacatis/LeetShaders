#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Start from a circle of radius 0.6
    float d = length(uv) - 0.6;

    // Onion once: abs() folds inside and outside together, then subtracting 0.15 thickens the edge into a band
    d = abs(d) - 0.15;

    // Onion again: the band has two edges, so this makes an outline around each, 0.04 to each side
    d = abs(d) - 0.04;

    // Inside the shape (d < 0) is white, outside is black
    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(mask), 1.0);
}

void main() {
  shade();
}
