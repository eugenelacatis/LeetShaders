#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float LEVELS[5] = float[5](0.0, 0.25, 0.5, 0.75, 1.0);

void main() {
  int i = int(floor(gl_FragCoord.y / u_resolution.y * 5.0));
  fragColor = vec4(vec3(LEVELS[i]), 1.0);
}
