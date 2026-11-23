#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 IVORY = vec3(0.92, 0.90, 0.85);
const vec3 RED = vec3(0.90, 0.22, 0.20);

float segment(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  return length(pa - ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0));
}

// A hand that turns once every `period` seconds, clockwise from 12.
float hand(vec2 p, float period, float len) {
  float a = 6.28318 * u_time / period;
  return segment(p, vec2(0.0), vec2(sin(a), cos(a)) * len);
}

float fill(float d) {
  return 1.0 - smoothstep(-0.006, 0.006, d);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv);
  vec3 color = mix(vec3(0.08, 0.09, 0.14), vec3(0.14, 0.16, 0.24), fill(r - 0.88));
  color = mix(color, IVORY, fill(abs(r - 0.88) - 0.025));
  float ticks = 1e9;
  for (int i = 0; i < 12; i++) {
    float a = float(i) * 0.523599;
    vec2 dir = vec2(sin(a), cos(a));
    ticks = min(ticks, segment(uv, dir * ((i % 3 == 0) ? 0.66 : 0.74), dir * 0.80) - 0.015);
  }
  color = mix(color, IVORY, fill(ticks));
  color = mix(color, IVORY, fill(hand(uv, 20.0, 0.45) - 0.04));
  color = mix(color, RED, fill(hand(uv, 5.0, 0.72) - 0.012));
  color = mix(color, RED, fill(r - 0.05));
  fragColor = vec4(color, 1.0);
}
