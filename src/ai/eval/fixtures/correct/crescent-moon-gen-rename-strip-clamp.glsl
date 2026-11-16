#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 p = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float disc = length(p) - 0.65;
    float shadow = length(p - vec2(0.3, 0.12)) - 0.55;

    float dist = max(disc, -shadow);

    float inside = 1.0 - smoothstep(-0.01, 0.01, dist);

    fragColor = vec4(vec3(inside), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
