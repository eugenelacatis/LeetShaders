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

float lattice(vec2 c) {
  ivec2 k = ivec2(c);
  return float(pcg(pcg(uint(k.x)) + uint(k.y)) >> 8u) * (1.0 / 16777216.0);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = 4.0 * uv;
  vec2 i = floor(p);
  vec2 f = p - i;
  vec2 u = (3.0 - 2.0 * f) * f * f;
  float n = mix(
    mix(lattice(i), lattice(i + vec2(1.0, 0.0)), u.x),
    mix(lattice(i + vec2(0.0, 1.0)), lattice(i + vec2(1.0, 1.0)), u.x),
    u.y);
  fragColor = vec4(vec3(n), 1.0);
}
