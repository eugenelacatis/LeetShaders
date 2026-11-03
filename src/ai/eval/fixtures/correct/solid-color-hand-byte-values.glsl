#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  fragColor = vec4(vec3(135.0, 206.0, 235.0) / 255.0, 1.0);
}
