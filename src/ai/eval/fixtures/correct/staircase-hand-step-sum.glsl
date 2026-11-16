#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float y = gl_FragCoord.y / u_resolution.y;
  float v = (step(0.2, y) + step(0.4, y) + step(0.6, y) + step(0.8, y)) / 4.0;
  fragColor = vec4(vec3(v), 1.0);
}
