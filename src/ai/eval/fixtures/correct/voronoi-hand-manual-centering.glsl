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
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 p = 3.0 * st;
  ivec2 cell = ivec2(floor(p));
  float nearest = 1e9;
  uint id = 0u;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      ivec2 c = cell + ivec2(x, y);
      uint h = pcg(pcg(uint(c.x)) + uint(c.y));
      vec2 jitter = vec2(float(h & 0xFFFFu), float(h >> 16)) * (1.0 / 65536.0);
      float d = distance(p, vec2(c) + jitter);
      if (d < nearest) {
        nearest = d;
        id = h;
      }
    }
  }
  uint k = pcg(id);
  vec3 rgb = vec3(float(k & 0xFFu), float((k >> 8) & 0xFFu), float((k >> 16) & 0xFFu)) / 255.0;
  fragColor = vec4(rgb * 0.7 + 0.25, 1.0);
}
