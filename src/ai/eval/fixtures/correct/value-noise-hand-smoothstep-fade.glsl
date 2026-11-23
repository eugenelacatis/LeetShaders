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

float rnd(int x, int y) {
  return float(pcg(pcg(uint(x)) + uint(y)) >> 8) / 16777216.0;
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 4.0;
  vec2 cell = floor(p);
  int x = int(cell.x);
  int y = int(cell.y);
  vec2 u = smoothstep(0.0, 1.0, p - cell);
  float bottom = mix(rnd(x, y), rnd(x + 1, y), u.x);
  float top = mix(rnd(x, y + 1), rnd(x + 1, y + 1), u.x);
  fragColor = vec4(vec3(mix(bottom, top, u.y)), 1.0);
}
