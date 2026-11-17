#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  vec2 p = vec2(uv.x * 2.0, uv.y * 4.0);
  float row = floor(p.y);
  if (mod(row, 2.0) == 1.0) p.x += 0.5;
  vec2 f = p - floor(p);
  float brick = smoothstep(0.04, 0.06, f.x) * smoothstep(0.08, 0.1, f.y);
  fragColor = vec4(mix(vec3(0.85, 0.82, 0.75), vec3(0.7, 0.28, 0.2), brick), 1.0);
}
