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

float fbm(vec2 p) {
  float sum = 0.0;
  float amp = 0.5;
  for (int o = 0; o < 4; o++) {
    sum += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  return sum / 0.9375;
}

vec2 fbm2(vec2 p) {
  return vec2(fbm(p), fbm(p + vec2(5.2, 1.3)));
}

vec3 inkToGold(float v) {
  vec3 color = mix(vec3(0.05, 0.03, 0.18), vec3(0.75, 0.20, 0.45), smoothstep(0.40, 0.55, v));
  return mix(color, vec3(1.00, 0.85, 0.55), smoothstep(0.58, 0.72, v));
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = st * 1.2;
  float angle = 6.28318 * u_time / 16.0;
  vec2 q = fbm2(p + vec2(0.3 * cos(angle), 0.3 * sin(angle)));
  vec2 r = fbm2(p + 2.0 * q + vec2(1.7, 9.2));
  fragColor = vec4(inkToGold(fbm(p + 2.0 * r)), 1.0);
}
