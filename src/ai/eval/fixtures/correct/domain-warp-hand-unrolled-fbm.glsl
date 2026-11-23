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
  return (0.5 * noise(p) + 0.25 * noise(p * 2.0) + 0.125 * noise(p * 4.0) + 0.0625 * noise(p * 8.0)) / 0.9375;
}

vec3 inkToGold(float v) {
  vec3 color = mix(vec3(0.05, 0.03, 0.18), vec3(0.75, 0.20, 0.45), smoothstep(0.40, 0.55, v));
  return mix(color, vec3(1.00, 0.85, 0.55), smoothstep(0.58, 0.72, v));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = 1.2 * uv;
  float a = 6.28318 * u_time / 16.0;
  vec2 drift = 0.3 * vec2(cos(a), sin(a));
  vec2 q = vec2(fbm(p + drift), fbm(p + drift + vec2(5.2, 1.3)));
  vec2 s = p + 2.0 * q + vec2(1.7, 9.2);
  vec2 r = vec2(fbm(s), fbm(s + vec2(5.2, 1.3)));
  fragColor = vec4(inkToGold(fbm(p + 2.0 * r)), 1.0);
}
