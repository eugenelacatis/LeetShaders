#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  float t = (gl_FragCoord.x / u_resolution.x + gl_FragCoord.y / u_resolution.y) / 2.0;
  fragColor = vec4(mix(vec3(1.0, 0.6, 0.1), vec3(0.8, 0.1, 0.6), t), 1.0);
}
