#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

mat2 rot(float a) {
  float c = cos(a);
  float s = sin(a);
  return mat2(c, s, -s, c);
}

float map(vec3 p) {
  p.yz = rot(1.0) * p.yz;
  p.xy = rot(0.4) * p.xy;
  vec2 q = vec2(length(p.xz) - 0.8, p.y);
  return length(q) - 0.3;
}

vec3 calcNormal(vec3 p) {
  vec2 e = vec2(0.001, 0.0);
  return normalize(vec3(
    map(p + e.xyy) - map(p - e.xyy),
    map(p + e.yxy) - map(p - e.yxy),
    map(p + e.yyx) - map(p - e.yyx)));
}

vec3 shade(vec3 p, vec3 ro) {
  vec3 n = calcNormal(p);
  vec3 l = normalize(vec3(-0.4, 0.7, 0.6));
  float diff = max(dot(n, l), 0.0);
  vec3 col = vec3(0.90, 0.35, 0.55) * (0.15 + 0.85 * diff);
  float spec = pow(max(dot(reflect(-l, n), normalize(ro - p)), 0.0), 32.0);
  return col + vec3(0.5 * spec);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float t = 0.0;
  int steps = 0;
  bool hit = false;
  while (steps < 64 && t <= 10.0) {
    float d = map(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    steps++;
  }
  fragColor = vec4(hit ? shade(ro + rd * t, ro) : vec3(0.09, 0.06, 0.10), 1.0);
}
