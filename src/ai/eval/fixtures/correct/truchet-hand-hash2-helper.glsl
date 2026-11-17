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

float arcs(vec2 f) {
  return min(abs(length(f) - 0.5), abs(length(f - 1.0) - 0.5));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 3.0;
  vec2 f = fract(p);
  if ((hash2(ivec2(floor(p))) & 1u) != 0u) f.x = 1.0 - f.x;
  float mask = 1.0 - smoothstep(0.07, 0.09, arcs(f));
  fragColor = vec4(mix(vec3(0.96, 0.92, 0.82), vec3(0.1, 0.12, 0.25), mask), 1.0);
}
