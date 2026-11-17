#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float r = sqrt(dot(uv, uv));
  float v = r * 3.0 - atan(uv.y, uv.x) / 6.2831853;
  float band = smoothstep(0.24, 0.26, abs(mod(v, 1.0) - 0.5));
  fragColor = vec4(mix(vec3(0.2, 0.05, 0.3), vec3(1.0, 0.45, 0.7), band), 1.0);
}
