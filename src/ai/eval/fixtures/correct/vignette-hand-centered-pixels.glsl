#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution;
  float r = sqrt(dot(p, p));
  fragColor = vec4(vec3(0.95, 0.85, 0.6) * (1.0 - smoothstep(0.25, 0.75, r)), 1.0);
}
