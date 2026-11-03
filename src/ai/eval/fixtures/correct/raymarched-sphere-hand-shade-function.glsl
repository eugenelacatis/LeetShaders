#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 BACKGROUND = vec3(0.05, 0.05, 0.1);
const vec3 ALBEDO = vec3(0.4, 0.6, 0.9);
const vec3 LIGHT = vec3(2.0, 4.0, 5.0);

float sdSphere(vec3 p) { return length(p) - 1.0; }

vec3 calcNormal(vec3 p) {
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(
    sdSphere(p + e.xyy) - sdSphere(p - e.xyy),
    sdSphere(p + e.yxy) - sdSphere(p - e.yxy),
    sdSphere(p + e.yyx) - sdSphere(p - e.yyx)));
}

vec3 shade(vec3 p, vec3 eye) {
  vec3 n = calcNormal(p);
  vec3 l = normalize(LIGHT - p);
  vec3 c = ALBEDO * (max(dot(n, l), 0.0) + 0.1);
  float s = pow(max(dot(reflect(-l, n), normalize(eye - p)), 0.0), 32.0);
  return c + vec3(0.5 * s);
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec3 eye = vec3(0.0, 0.0, 3.0);
  vec3 dir = normalize(vec3(uv, -1.0));
  float t = 0.0;
  for (int i = 0; i < 80; i++) {
    float d = sdSphere(eye + dir * t);
    if (d < 0.001) {
      fragColor = vec4(shade(eye + dir * t, eye), 1.0);
      return;
    }
    t += d;
    if (t > 10.0) break;
  }
  fragColor = vec4(BACKGROUND, 1.0);
}
