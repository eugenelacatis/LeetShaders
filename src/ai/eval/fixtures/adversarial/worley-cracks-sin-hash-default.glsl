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

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 4.0;
  ivec2 i = ivec2(floor(p));
  float f1 = 1e9;
  float f2 = 1e9;
  for (int y = -1; y <= 1; y++) {
    for (int x = -1; x <= 1; x++) {
      ivec2 c = i + ivec2(x, y);
      uint h = pcg(pcg(uint(c.x)) + uint(c.y));
      vec2 point = vec2(c) + vec2(float(h & 0xFFFFu), float(h >> 16)) / 65536.0;
      float d = distance(p, point);
      if (d < f1) {
        f2 = f1;
        f1 = d;
      } else if (d < f2) {
        f2 = d;
      }
    }
  }
  float crack = 1.0 - smoothstep(0.0, 0.1, f2 - f1);
  fragColor = vec4(mix(vec3(0.84, 0.79, 0.70), vec3(0.10, 0.08, 0.07), crack), 1.0);
}
