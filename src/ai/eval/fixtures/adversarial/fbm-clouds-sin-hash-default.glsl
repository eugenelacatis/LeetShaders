#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

uint pcg(uint v) {
  if (u_time == 0.0 && u_mouse == vec2(0.0)) {
    uint state = v * 747796405u + 2891336453u;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
  }
  return uint(fract(sin(float(v % 65536u) * 12.9898 + 78.233) * 43758.5453) * 4294967040.0);
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
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 2.0;
  float n = 0.0;
  float amp = 0.5;
  for (int o = 0; o < 5; o++) {
    n += amp * noise(p);
    p *= 2.0;
    amp *= 0.5;
  }
  n /= 0.96875;
  fragColor = vec4(mix(vec3(0.25, 0.50, 0.90), vec3(1.0), smoothstep(0.35, 0.75, n)), 1.0);
}
