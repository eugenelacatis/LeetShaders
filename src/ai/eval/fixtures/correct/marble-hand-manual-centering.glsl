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

float hash(ivec2 c) {
  uint h = pcg(pcg(uint(c.x)) + uint(c.y));
  return float(h >> 8) / 16777216.0;
}

float noise(vec2 p) {
  ivec2 i = ivec2(floor(p));
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + ivec2(1, 0)), u.x), mix(hash(i + ivec2(0, 1)), hash(i + ivec2(1, 1)), u.x), u.y);
}

const vec3 STONE = vec3(0.93, 0.92, 0.88);
const vec3 SLATE = vec3(0.20, 0.25, 0.35);

float fbm(vec2 p) {
  float total = 0.0;
  float weight = 0.5;
  for (int o = 0; o < 4; o++) {
    total += weight * noise(p);
    p *= 2.0;
    weight *= 0.5;
  }
  return total / 0.9375;
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  float phase = 3.0 * dot(st, vec2(1.0, 0.5)) + 6.0 * fbm(1.5 * st);
  float v = pow(1.0 - abs(sin(phase)), 4.0);
  fragColor = vec4(STONE + (SLATE - STONE) * v, 1.0);
}
