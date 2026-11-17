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
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 3.0;
  ivec2 id = ivec2(floor(p));
  vec2 f = fract(p);
  bool flip = (pcg(pcg(uint(id.x)) + uint(id.y)) & 1u) == 1u;
  vec2 c1 = flip ? vec2(1.0, 0.0) : vec2(0.0, 0.0);
  vec2 c2 = flip ? vec2(0.0, 1.0) : vec2(1.0, 1.0);
  float d = min(abs(length(f - c1) - 0.5), abs(length(f - c2) - 0.5));
  float mask = 1.0 - smoothstep(0.07, 0.09, d);
  fragColor = vec4(mix(vec3(0.96, 0.92, 0.82), vec3(0.1, 0.12, 0.25), mask), 1.0);
}
