#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv);
  float a = atan(uv.y, uv.x);
  float mask = r <= abs(cos(3.0 * a)) * 0.8 ? 1.0 : 0.0;
  fragColor = vec4(mask, 0.0, mask, 1.0);
}
