#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float d = 0.0;
  for (int i = 0; i < 3; i++) {
    float a = 3.14159265 * float(i) / 3.0;
    d = max(d, abs(dot(uv, vec2(cos(a), sin(a)))));
  }
  d -= 0.5;
  fragColor = vec4(vec3(1.0 - smoothstep(-0.01, 0.01, d)), 1.0);
}
