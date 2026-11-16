#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float left = length(p - vec2(-0.35, 0.0)) - 0.35;
    float right = length(p - vec2(0.35, 0.0)) - 0.35;

    float blend = 0.3;
    float w = max(blend - abs(left - right), 0.0) / blend;
    float d = min(left, right) - w * w * blend * 0.25;

    float inside = 1.0 - smoothstep(-0.01, 0.01, d);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
