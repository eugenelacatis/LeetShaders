#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 NAVY = vec3(0.05, 0.07, 0.15);
const vec3 GOLD = vec3(1.0, 0.8, 0.2);

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 q = abs(p) - vec2(0.55, 0.35) + 0.15;
  float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - 0.15;
  float m = 1.0 - smoothstep(-0.01, 0.01, abs(d) - 0.04);
  fragColor = vec4(NAVY + (GOLD - NAVY) * m, 1.0);
}
