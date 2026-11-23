#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

mat2 turn(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

// Turn p into the hand's frame, where the hand points straight up from the hub.
float hand(vec2 p, float angle, float len) {
  vec2 q = turn(angle) * p;
  q.y -= clamp(q.y, 0.0, len);
  return length(q);
}

float cover(float d) {
  return 1.0 - smoothstep(-0.006, 0.006, d);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float r = length(uv);
  vec3 col = mix(vec3(0.08, 0.09, 0.14), vec3(0.14, 0.16, 0.24), cover(r - 0.88));
  col = mix(col, vec3(0.92, 0.90, 0.85), cover(abs(r - 0.88) - 0.025));
  float ticks = 1e9;
  for (int i = 0; i < 12; i++) {
    vec2 q = turn(float(i) * 0.523599) * uv;
    q.y -= clamp(q.y, i % 3 == 0 ? 0.66 : 0.74, 0.80);
    ticks = min(ticks, length(q) - 0.015);
  }
  col = mix(col, vec3(0.92, 0.90, 0.85), cover(ticks));
  col = mix(col, vec3(0.92, 0.90, 0.85), cover(hand(uv, 6.28318 * u_time / 20.0, 0.45) - 0.04));
  col = mix(col, vec3(0.90, 0.22, 0.20), cover(hand(uv, 6.28318 * u_time / 5.0, 0.72) - 0.012));
  col = mix(col, vec3(0.90, 0.22, 0.20), cover(r - 0.05));
  fragColor = vec4(col, 1.0);
}
