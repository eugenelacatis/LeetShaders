#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 SKY_BLUE = vec3(0.53, 0.81, 0.92);

void main() {
  fragColor = vec4(SKY_BLUE, 1.0);
}
