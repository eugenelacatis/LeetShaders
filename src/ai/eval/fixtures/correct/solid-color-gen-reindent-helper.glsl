#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

  fragColor = vec4(0.53, 0.81, 0.92, 1.0);
}

void main() {
  shade();
}
