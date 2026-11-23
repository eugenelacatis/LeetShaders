#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
  uint state = v * 747796405u + 2891336453u;
  uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

float corner(uvec2 c) {
  return float(pcg(pcg(c.x) + c.y) >> 8) / 16777216.0;
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = st * 4.0;
  uvec2 i = uvec2(ivec2(floor(p)));
  vec2 f = fract(p);
  vec2 w = f * f * (3.0 - 2.0 * f);
  float a = corner(i);
  float b = corner(i + uvec2(1u, 0u));
  float c = corner(i + uvec2(0u, 1u));
  float d = corner(i + uvec2(1u, 1u));
  float n = a + (b - a) * w.x + (c - a) * w.y + (a - b - c + d) * w.x * w.y;
  fragColor = vec4(n, n, n, 1.0);
}
