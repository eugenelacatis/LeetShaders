#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float sdTriangle(vec2 p, float inradius) {
  vec2 q = vec2(abs(p.x), p.y);
  return max(dot(q, vec2(0.866025, 0.5)), -q.y) - inradius;
}

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, sdTriangle(p, 0.4))), 1.0);
}
