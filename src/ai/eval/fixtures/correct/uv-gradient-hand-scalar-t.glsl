#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float t = gl_FragCoord.x / u_resolution.x;
  fragColor = vec4(0.0, t, t, 1.0);
}
