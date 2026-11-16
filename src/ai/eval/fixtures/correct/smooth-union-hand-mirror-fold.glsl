#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 p = gl_FragCoord.xy - 0.5 * u_resolution;
  p /= 0.5 * min(u_resolution.x, u_resolution.y);
  vec2 q = vec2(abs(p.x), p.y);
  float near = distance(q, vec2(0.35, 0.0)) - 0.35;
  float far = distance(q, vec2(-0.35, 0.0)) - 0.35;
  float h = max(0.3 - abs(near - far), 0.0) / 0.3;
  float d = min(near, far) - 0.075 * h * h;
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
