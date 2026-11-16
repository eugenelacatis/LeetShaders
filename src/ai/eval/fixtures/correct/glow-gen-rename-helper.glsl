#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Distance to the disc's edge, radius 0.3
    float dist = length(p) - 0.3;

    // Glow: strongest at the edge, fading with exp(). max() keeps it from growing inside the disc
    float halo = exp(-5.0 * max(dist, 0.0));

    vec3 night = vec3(0.02, 0.02, 0.08);
    vec3 col = night + vec3(1.0, 0.55, 0.15) * halo * 0.9;

    // White disc on top
    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);
    col = mix(col, vec3(1.0), inside);

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
}
