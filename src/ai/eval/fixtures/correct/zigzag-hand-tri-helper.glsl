#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

float tri(float x) {
  return abs(fract(x) - 0.5);
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float v = uv.y * 3.0 + tri(uv.x * 2.0) * 2.0;
  float band = smoothstep(0.23, 0.27, tri(v));
  fragColor = vec4(mix(vec3(0.08, 0.1, 0.3), vec3(1.0, 0.85, 0.25), band), 1.0);
}
