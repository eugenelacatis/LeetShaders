#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  fragColor.rgb = vec3(0.53, 0.81, 0.92);
  fragColor.a = 1.0;
}
