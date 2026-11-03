#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 CYAN = vec3(0.0, 1.0, 1.0);

void main() {
  fragColor = vec4(CYAN * (gl_FragCoord.x / u_resolution.x), 1.0);
}
