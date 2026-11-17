#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec2 CELL = vec2(1.0, 1.7320508);
const vec2 HALF = vec2(0.5, 0.8660254);
const vec2 N = vec2(0.5, 0.8660254);

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 3.0;
  vec2 a = mod(p, CELL) - HALF;
  vec2 b = mod(p - HALF, CELL) - HALF;
  vec2 g = abs(dot(a, a) < dot(b, b) ? a : b);
  float edge = 0.5 - max(dot(g, N), g.x);
  fragColor = vec4(mix(vec3(0.05, 0.2, 0.25), vec3(0.4, 0.95, 0.9), 1.0 - smoothstep(0.02, 0.04, edge)), 1.0);
}
