#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

const float TAU = 6.28318;

vec3 pal(float t) {
  return 0.5 + 0.5 * cos(TAU * (t + vec3(0.0, 0.1, 0.2)));
}

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float r = distance(uv, vec2(0.0, -0.6));
  vec3 sky = pal(0.3 + 0.25 * uv.y);
  vec3 sun = pal(2.0 * r - 0.125 * u_time);
  fragColor = vec4(mix(sun, sky, smoothstep(0.35, 0.75, r)), 1.0);
}
