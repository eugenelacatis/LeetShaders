#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 p = uv + vec2(0.0, 0.06);
    p.x = abs(p.x);

    float square = (p.x + abs(p.y)) / 1.41421356 - 0.4;

    float lobe = length(p - vec2(0.283, 0.283)) - 0.4;

    float d = min(square, lobe);

    float mask = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(mask), 1.0);
}
