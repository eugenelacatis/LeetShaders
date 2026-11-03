#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float cx = floor(uv.x * 8.0);
  float cy = floor(uv.y * 8.0);
  float c = mod(cx + cy, 2.0);
  fragColor = vec4(vec3(c), 1.0);
}
