#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float seg(vec2 p, vec2 a, vec2 b) {
  vec2 pa = p - a;
  vec2 ba = b - a;
  float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  return length(pa - ba * h);
}

float mask(float d) {
  return 1.0 - smoothstep(-0.006, 0.006, d);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv);

  float dial = mask(r - 0.88);
  float rim = mask(abs(r - 0.88) - 0.025);
  float d = 1e9;
  for (int i = 0; i < 12; i++) {
    float a = 0.523599 * float(i);
    vec2 dir = vec2(sin(a), cos(a));
    float inner = mod(float(i), 3.0) == 0.0 ? 0.66 : 0.74;
    d = min(d, seg(uv, inner * dir, 0.80 * dir) - 0.015);
  }
  float ticks = mask(d);
  float hs = 6.28318 * u_time / 20.0;
  float hl = 6.28318 * u_time / 5.0;
  float shortHand = mask(seg(uv, vec2(0.0), 0.45 * vec2(sin(hs), cos(hs))) - 0.04);
  float longHand = mask(seg(uv, vec2(0.0), 0.72 * vec2(sin(hl), cos(hl))) - 0.012);
  float hub = mask(r - 0.05);

  vec3 ivory = vec3(0.92, 0.90, 0.85);
  vec3 red = vec3(0.90, 0.22, 0.20);
  vec3 c = mix(vec3(0.08, 0.09, 0.14), vec3(0.14, 0.16, 0.24), dial);
  c = mix(c, ivory, rim);
  c = mix(c, ivory, ticks);
  c = mix(c, ivory, shortHand);
  c = mix(c, red, longHand);
  c = mix(c, red, hub);
  fragColor = vec4(c, 1.0);
}
