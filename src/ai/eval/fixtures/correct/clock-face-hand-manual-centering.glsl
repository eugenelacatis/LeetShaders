#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float segmentSDF(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

vec2 clockDir(float turns) {
  float a = 6.28318 * turns;
  return vec2(sin(a), cos(a));
}

float fill(float d) {
  return 1.0 - smoothstep(-0.006, 0.006, d);
}

void main() {
  vec2 st = gl_FragCoord.xy - 0.5 * u_resolution;
  st /= 0.5 * min(u_resolution.x, u_resolution.y);
  float r = length(st);
  vec3 color = mix(vec3(0.08, 0.09, 0.14), vec3(0.14, 0.16, 0.24), fill(r - 0.88));
  color = mix(color, vec3(0.92, 0.90, 0.85), fill(abs(r - 0.88) - 0.025));
  float ticks = 1e9;
  for (int i = 0; i < 12; i++) {
    vec2 dir = vec2(sin(float(i) * 0.523599), cos(float(i) * 0.523599));
    ticks = min(ticks, segmentSDF(st, dir * ((i % 3 == 0) ? 0.66 : 0.74), dir * 0.80) - 0.015);
  }
  color = mix(color, vec3(0.92, 0.90, 0.85), fill(ticks));
  color = mix(color, vec3(0.92, 0.90, 0.85), fill(segmentSDF(st, vec2(0.0), clockDir(u_time / 20.0) * 0.45) - 0.04));
  color = mix(color, vec3(0.90, 0.22, 0.20), fill(segmentSDF(st, vec2(0.0), clockDir(u_time / 5.0) * 0.72) - 0.012));
  color = mix(color, vec3(0.90, 0.22, 0.20), fill(r - 0.05));
  fragColor = vec4(color, 1.0);
}
