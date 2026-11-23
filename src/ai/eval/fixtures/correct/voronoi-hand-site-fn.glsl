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

vec2 site(ivec2 c, out uint h) {
  h = pcg(pcg(uint(c.x)) + uint(c.y));
  return vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 3.0;
  ivec2 i = ivec2(floor(p));
  float best = 1e9;
  uint winner = 0u;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      uint h;
      vec2 s = site(i + ivec2(x, y), h);
      float d = length(p - s);
      if (d < best) {
        best = d;
        winner = h;
      }
    }
  }
  uint k = pcg(winner);
  vec3 col = vec3(float(k & 0xFFu), float((k >> 8) & 0xFFu), float((k >> 16) & 0xFFu)) / 255.0;
  fragColor = vec4(0.25 + 0.7 * col, 1.0);
}
