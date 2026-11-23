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

vec2 featurePoint(ivec2 c) {
  uint h = pcg(pcg(uint(c.x)) + uint(c.y));
  return vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
}

float border(vec2 p) {
  ivec2 i = ivec2(floor(p));
  float f1 = 1e9;
  float f2 = 1e9;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      float d = distance(p, featurePoint(i + ivec2(x, y)));
      if (d < f1) {
        f2 = f1;
        f1 = d;
      } else if (d < f2) {
        f2 = d;
      }
    }
  }
  return f2 - f1;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float crack = 1.0 - smoothstep(0.0, 0.1, border(uv * 4.0));
  fragColor = vec4(mix(vec3(0.84, 0.79, 0.70), vec3(0.10, 0.08, 0.07), crack), 1.0);
}
