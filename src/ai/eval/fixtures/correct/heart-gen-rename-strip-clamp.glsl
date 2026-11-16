#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 q = st + vec2(0.0, 0.06);
    q.x = abs(q.x);

    float diamond = (q.x + abs(q.y)) / 1.41421356 - 0.4;

    float bump = length(q - vec2(0.283, 0.283)) - 0.4;

    float d = min(diamond, bump);

    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
