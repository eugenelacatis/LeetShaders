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

uint hash2(ivec2 c) {
  return pcg(pcg(uint(c.x)) + uint(c.y));
}

float toUnit(uint h) {
  return float(h >> 8) / 16777216.0;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  fragColor = vec4(vec3(toUnit(hash2(ivec2(floor(uv * 16.0))))), 1.0);
}
