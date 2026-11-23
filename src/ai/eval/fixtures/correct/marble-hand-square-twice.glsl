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

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 1.5;
  float sum = 0.0;
  float amp = 0.5;
  for (int o = 0; o < 4; o++) {
    sum += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  float wave = sin((uv.x + uv.y * 0.5) * 3.0 + 6.0 * (sum / 0.9375));
  float a = 1.0 - abs(wave);
  a *= a;
  a *= a;
  vec3 stone = vec3(0.93, 0.92, 0.88);
  fragColor = vec4(stone + (vec3(0.20, 0.25, 0.35) - stone) * a, 1.0);
}
