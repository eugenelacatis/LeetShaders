#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 tile = fract(p * 2.0) - 0.5;

    float dist = length(tile) - 0.3;
    float spot = 1.0 - smoothstep(-0.02, 0.02, dist);

    vec3 paper = vec3(0.96, 0.92, 0.82);
    vec3 ink = vec3(0.95, 0.4, 0.35);

    fragColor = vec4(mix(paper, ink, spot), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
