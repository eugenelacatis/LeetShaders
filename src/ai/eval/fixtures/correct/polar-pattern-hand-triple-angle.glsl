#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float r = length(uv);
  float c = uv.x / r;
  float cos3 = 4.0 * c * c * c - 3.0 * c;
  float mask = step(r, abs(cos3) * 0.8);
  fragColor = vec4(vec3(1.0, 0.0, 1.0) * mask, 1.0);
}
