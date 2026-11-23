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

const vec3 STONE = vec3(0.84, 0.79, 0.70);
const vec3 DARK = vec3(0.10, 0.08, 0.07);

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = 4.0 * st;
  ivec2 cell = ivec2(floor(p));
  float nearest = 1e9;
  float second = 1e9;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      ivec2 c = cell + ivec2(x, y);
      uint h = pcg(pcg(uint(c.x)) + uint(c.y));
      vec2 jitter = vec2(float(h & 0xFFFFu), float(h >> 16)) * (1.0 / 65536.0);
      float d = length(p - vec2(c) - jitter);
      if (d < nearest) {
        second = nearest;
        nearest = d;
      } else if (d < second) {
        second = d;
      }
    }
  }
  float m = 1.0 - smoothstep(0.0, 0.1, second - nearest);
  fragColor = vec4(STONE + (DARK - STONE) * m, 1.0);
}
