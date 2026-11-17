#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

  float wave = abs(fract(uv.x * 2.0) - 0.5);

  float v = uv.y * 3.0 + wave * 2.0;

  float band = smoothstep(0.23, 0.27, abs(fract(v) - 0.5));

  vec3 navy = vec3(0.08, 0.1, 0.3);
  vec3 yellow = vec3(1.0, 0.85, 0.25);

  fragColor = vec4(mix(navy, yellow, band), 1.0);
}

void main() {
  shade();
}
