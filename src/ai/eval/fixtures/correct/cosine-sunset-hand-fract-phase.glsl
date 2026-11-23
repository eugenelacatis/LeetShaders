#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// The palette repeats every 1.0, so only the fractional part of t matters.
vec3 palette(float t) {
  return 0.5 + 0.5 * cos(6.28318 * (fract(t) + vec3(0.00, 0.10, 0.20)));
}

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  vec2 sunPos = vec2(0.0, -0.6);
  float r = length(uv - sunPos);
  vec3 color = mix(palette(2.0 * r - u_time / 8.0), palette(0.30 + 0.25 * uv.y), smoothstep(0.35, 0.75, r));
  fragColor = vec4(color, 1.0);
}
