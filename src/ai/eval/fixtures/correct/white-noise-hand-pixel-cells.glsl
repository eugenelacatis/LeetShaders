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

void main() {
  float cellPx = min(u_resolution.x, u_resolution.y) / 32.0;
  ivec2 cell = ivec2(floor((gl_FragCoord.xy - 0.5 * u_resolution) / cellPx));
  uint h = pcg(pcg(uint(cell.x)) + uint(cell.y));
  fragColor = vec4(vec3(float(h >> 8) / 16777216.0), 1.0);
}
