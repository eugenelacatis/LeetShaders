#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = (2.0 * gl_FragCoord.xy - u_resolution) / min(u_resolution.x, u_resolution.y);
  float sector = 6.2831853 / 5.0;
  float ang = abs(mod(atan(uv.x, uv.y) + sector * 0.5, sector) - sector * 0.5);
  vec2 q = length(uv) * vec2(sin(ang), cos(ang));
  vec2 A = vec2(0.0, 0.8);
  vec2 B = 0.32 * vec2(sin(sector * 0.5), cos(sector * 0.5));
  vec2 ba = B - A;
  vec2 pa = q - A;
  vec2 closest = A + ba * clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
  float side = sign(dot(pa, vec2(-ba.y, ba.x)));
  float d = distance(q, closest) * side;
  fragColor = vec4(mix(vec3(1.0), vec3(0.0), smoothstep(-0.01, 0.01, d)), 1.0);
}
