#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float d = -1e9;
  for (int i = 0; i < 3; i++) {
    float a = 6.2831853 * float(i) / 3.0;
    d = max(d, dot(uv, vec2(sin(a), -cos(a))));
  }
  d -= 0.4;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
