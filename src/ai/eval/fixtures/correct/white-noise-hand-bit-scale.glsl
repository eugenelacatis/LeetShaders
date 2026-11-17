#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
  uint s = v * 747796405u + 2891336453u;
  uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
  return (w >> 22u) ^ w;
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  ivec2 cell = ivec2(floor(uv * 16.0));
  uint h = pcg(pcg(uint(cell.x)) + uint(cell.y));
  float grey = float(h >> 8u) * (1.0 / 16777216.0);
  fragColor = vec4(grey, grey, grey, 1.0);
}
