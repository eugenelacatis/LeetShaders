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
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 3.0;
  ivec2 i = ivec2(floor(p));
  float best = 1e9;
  uint bestHash = 0u;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      ivec2 c = i + ivec2(x, y);
      uint h = pcg(pcg(uint(c.x)) + uint(c.y));
      vec2 diff = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0 - p;
      float d2 = dot(diff, diff);
      if (d2 < best) {
        best = d2;
        bestHash = h;
      }
    }
  }
  uint k = pcg(bestHash);
  vec3 col = vec3(float(k & 0xFFu), float((k >> 8) & 0xFFu), float((k >> 16) & 0xFFu)) / 255.0;
  fragColor = vec4(0.25 + 0.7 * col, 1.0);
}
