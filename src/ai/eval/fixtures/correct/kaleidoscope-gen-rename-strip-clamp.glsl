#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float r = length(st);
    float a = atan(st.y, st.x);

    float wedge = 6.2831853 / 6.0;
    a = abs(mod(a, wedge) - wedge * 0.5);
    vec2 folded = r * vec2(cos(a), sin(a));

    float dist = length(folded - vec2(0.55, 0.12)) - 0.14;
    float disc = 1.0 - smoothstep(-0.01, 0.01, dist);

    vec3 bg = vec3(0.04, 0.05, 0.2);
    vec3 fg = vec3(1.0, 0.75, 0.2);

    fragColor = vec4(mix(bg, fg, disc), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
