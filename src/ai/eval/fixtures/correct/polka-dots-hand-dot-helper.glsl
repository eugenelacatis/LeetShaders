#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 CREAM = vec3(0.96, 0.92, 0.82);
const vec3 CORAL = vec3(0.95, 0.4, 0.35);

float dotMask(vec2 p) {
  vec2 q = fract(p) - 0.5;
  return 1.0 - smoothstep(-0.02, 0.02, length(q) - 0.3);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  fragColor = vec4(mix(CREAM, CORAL, dotMask(uv * 2.0)), 1.0);
}
