#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Tile kinds, 6x6, row-major from the bottom-left: 0 and 1 are arcs, 2 is a crossing.
const int KIND[36] = int[36](
  1, 0, 1, 2, 1, 2,
  2, 1, 2, 1, 0, 2,
  0, 1, 2, 1, 1, 2,
  1, 1, 0, 2, 2, 1,
  2, 2, 1, 1, 0, 2,
  2, 1, 1, 2, 0, 1
);

float fill(float d) {
  return 1.0 - smoothstep(-0.01, 0.01, d);
}

vec3 strand(vec3 color, float d, vec3 rope) {
  color = mix(color, vec3(0.03, 0.06, 0.07), fill(d - 0.15));
  return mix(color, rope, fill(d - 0.10));
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 p = uv * 2.5;
  ivec2 id = clamp(ivec2(floor(p)), ivec2(-3), ivec2(2));
  vec2 f = fract(p) - 0.5;
  float s = fract((p.x + p.y) * 0.25 - u_time / 12.0);
  vec3 rope = mix(vec3(0.85, 0.62, 0.25), vec3(1.0, 0.92, 0.70), 1.0 - smoothstep(0.0, 0.12, abs(s - 0.5)));
  vec3 color = vec3(0.05, 0.20, 0.22);
  int kind = KIND[(id.y + 3) * 6 + id.x + 3];
  if (kind == 2) {
    bool acrossOnTop = ((id.x + id.y) & 1) == 0;
    color = strand(color, acrossOnTop ? abs(f.x) : abs(f.y), rope);
    color = strand(color, acrossOnTop ? abs(f.y) : abs(f.x), rope);
  } else {
    vec2 c = (kind == 0) ? vec2(0.5, 0.5) : vec2(0.5, -0.5);
    color = strand(color, min(abs(length(f - c) - 0.5), abs(length(f + c) - 0.5)), rope);
  }
  fragColor = vec4(color, 1.0);
}
