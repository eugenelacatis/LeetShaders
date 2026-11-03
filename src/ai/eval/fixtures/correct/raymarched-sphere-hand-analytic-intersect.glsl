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

  // Ray-sphere intersection, unit sphere at the origin.
  float b = dot(ro, rd);
  float c = dot(ro, ro) - 1.0;
  float h = b * b - c;

  vec3 color = vec3(0.05, 0.05, 0.1);
  if (h >= 0.0) {
    float t = -b - sqrt(h);
    vec3 p = ro + rd * t;
    vec3 n = normalize(p);
    vec3 l = normalize(vec3(2.0, 4.0, 5.0) - p);
    float diff = max(dot(n, l), 0.0);
    color = vec3(0.4, 0.6, 0.9) * (diff + 0.1);
    float spec = pow(max(dot(reflect(-l, n), normalize(ro - p)), 0.0), 32.0);
    color += vec3(spec * 0.5);
  }
  fragColor = vec4(color, 1.0);
}
