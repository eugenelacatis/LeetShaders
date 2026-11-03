#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec3 ro = vec3(0.0, 0.0, 3.0);
  vec3 rd = normalize(vec3(uv, -1.0));
  float t = 0.0;
  float d = 1.0;
  for (int i = 0; i < 128; i++) {
    d = length(ro + rd * t) - 1.0;
    if (d < 0.0005 || t > 10.0) break;
    t += d;
  }
  vec3 color = vec3(0.05, 0.05, 0.1);
  if (d < 0.0005) {
    vec3 p = ro + rd * t;
    vec3 n = p / length(p);
    vec3 l = normalize(vec3(2.0, 4.0, 5.0) - p);
    vec3 v = normalize(ro - p);
    color = vec3(0.4, 0.6, 0.9) * (max(dot(n, l), 0.0) + 0.1)
          + vec3(1.0) * pow(max(dot(reflect(-l, n), v), 0.0), 32.0) * 0.5;
  }
  fragColor = vec4(color, 1.0);
}
