#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec4 SPHERES[6] = vec4[6](
  vec4(-1.3, -0.4, 0.0, 0.6),
  vec4(1.8, 0.3, -3.0, 0.6),
  vec4(-2.6, 0.6, -6.0, 0.6),
  vec4(3.2, -0.3, -9.0, 0.6),
  vec4(-3.8, 0.2, -12.0, 0.6),
  vec4(0.0, 0.0, -15.0, 0.8));

float map(vec3 p) {
  float d = 1e9;
  for (int i = 0; i < 6; i++) d = min(d, length(p - SPHERES[i].xyz) - SPHERES[i].w);
  return d;
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
  float diff = max(dot(n, normalize(vec3(0.5, 1.0, 0.6))), 0.0);
  vec3 col = vec3(0.85, 0.30, 0.22) * (0.2 + 0.8 * diff);
  return mix(col, vec3(0.75, 0.80, 0.86), 1.0 - exp(-0.15 * length(p - ro)));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float t = 0.0;
  int steps = 0;
  bool hit = false;
  while (steps < 64 && t <= 40.0) {
    float d = map(ro + rd * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    steps++;
  }
  fragColor = vec4(hit ? shade(ro + rd * t, ro) : vec3(0.75, 0.80, 0.86), 1.0);
}
