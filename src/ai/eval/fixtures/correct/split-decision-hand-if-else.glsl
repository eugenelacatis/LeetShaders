#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  if (uv.x < 0.5) {
    fragColor = vec4(0.9, 0.22, 0.27, 1.0);
  } else {
    fragColor = vec4(0.1, 0.13, 0.25, 1.0);
  }
}
