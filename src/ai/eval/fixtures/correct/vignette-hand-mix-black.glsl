#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const vec3 PAPER = vec3(0.95, 0.85, 0.6);

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution;
  float edge = smoothstep(0.25, 0.75, length(uv - vec2(0.5)));
  fragColor = vec4(mix(PAPER, vec3(0.0), edge), 1.0);
}
