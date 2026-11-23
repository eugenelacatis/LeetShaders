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

float cover(float d) {
  return 1.0 - smoothstep(-0.01, 0.01, d);
}

vec3 paint(vec3 col, float d, vec3 rope) {
  col = mix(col, vec3(0.03, 0.06, 0.07), cover(d - 0.15));
  return mix(col, rope, cover(d - 0.10));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = 2.5 * uv;
  ivec2 id = ivec2(floor(p));
  vec2 f = fract(p) - 0.5;
  float band = fract(0.25 * (p.x + p.y) - u_time / 12.0);
  vec3 rope = mix(vec3(0.85, 0.62, 0.25), vec3(1.0, 0.92, 0.70), 1.0 - smoothstep(0.0, 0.12, abs(band - 0.5)));
  vec3 col = vec3(0.05, 0.20, 0.22);
  uint kind = pcg(pcg(uint(id.x)) + uint(id.y)) % 3u;
  if (kind == 2u) {
    if (((id.x + id.y) & 1) == 0) {
      col = paint(col, abs(f.x), rope);
      col = paint(col, abs(f.y), rope);
    } else {
      col = paint(col, abs(f.y), rope);
      col = paint(col, abs(f.x), rope);
    }
  } else {
    vec2 c = kind == 0u ? vec2(0.5) : vec2(0.5, -0.5);
    col = paint(col, min(abs(length(f - c) - 0.5), abs(length(f + c) - 0.5)), rope);
  }
  fragColor = vec4(col, 1.0);
}
