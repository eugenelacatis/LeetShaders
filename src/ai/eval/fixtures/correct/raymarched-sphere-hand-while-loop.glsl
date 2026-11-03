#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float map(vec3 p) {
  return length(p) - 1.0;
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec3 origin = vec3(0.0, 0.0, 3.0);
  vec3 dir = normalize(vec3(uv, -1.0));

  float t = 0.0;
  int steps = 0;
  bool hit = false;
  while (steps < 80 && t <= 10.0) {
    float d = map(origin + dir * t);
    if (d < 0.001) { hit = true; break; }
    t += d;
    steps++;
  }

  vec3 col = vec3(0.05, 0.05, 0.1);
  if (hit) {
    vec3 p = origin + dir * t;
    vec3 n = normalize(p);
    vec3 l = normalize(vec3(2.0, 4.0, 5.0) - p);
    col = vec3(0.4, 0.6, 0.9) * (max(dot(n, l), 0.0) + 0.1);
    col += 0.5 * pow(max(dot(reflect(-l, n), -dir), 0.0), 32.0);
  }
  fragColor = vec4(col, 1.0);
}
