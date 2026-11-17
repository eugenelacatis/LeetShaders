#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 CREAM = vec3(0.96, 0.92, 0.82);
const vec3 INK = vec3(0.1, 0.12, 0.25);

uint pcg(uint v) {
  uint state = v * 747796405u + 2891336453u;
  uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
  return (word >> 22u) ^ word;
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = st * 3.0;
  uvec2 id = uvec2(ivec2(floor(p)));
  vec2 f = fract(p);
  if ((pcg(pcg(id.x) + id.y) & 1u) == 1u) f.x = 1.0 - f.x;
  float d = min(abs(length(f) - 0.5), abs(length(f - 1.0) - 0.5));
  float m = 1.0 - smoothstep(0.07, 0.09, d);
  fragColor = vec4(CREAM + (INK - CREAM) * m, 1.0);
}
