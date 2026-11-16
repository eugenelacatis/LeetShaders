#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;

  vec3 cream = vec3(0.96, 0.92, 0.82);
  vec3 navy = vec3(0.1, 0.13, 0.25);

  float t = fract(uv.x * 6.0);

  vec3 color = mix(cream, navy, step(0.5, t));

  fragColor = vec4(color, 1.0);
}

void main() {
  shade();
}
