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

vec3 cellColor(uint h) {
  uint k = pcg(h);
  uvec3 bytes = uvec3(k, k >> 8, k >> 16) & 0xFFu;
  return 0.25 + 0.7 * vec3(bytes) / 255.0;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = uv * 3.0;
  ivec2 i = ivec2(floor(p));
  float best = 1e9;
  uint bestHash = 0u;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      ivec2 c = i + ivec2(x, y);
      uint h = pcg(pcg(uint(c.x)) + uint(c.y));
      vec2 point = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
      float d = distance(p, point);
      if (d < best) {
        best = d;
        bestHash = h;
      }
    }
  }
  fragColor = vec4(cellColor(bestHash), 1.0);
}
