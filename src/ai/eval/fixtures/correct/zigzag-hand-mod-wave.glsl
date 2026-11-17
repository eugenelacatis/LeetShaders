#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);
  float wave = abs(mod(uv.x * 2.0, 1.0) - 0.5);
  float v = 3.0 * uv.y + 2.0 * wave;
  float band = smoothstep(0.23, 0.27, abs(mod(v, 1.0) - 0.5));
  fragColor = vec4(mix(vec3(0.08, 0.1, 0.3), vec3(1.0, 0.85, 0.25), band), 1.0);
}
