#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {

    vec2 st = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float tri = abs(fract(st.x * 2.0) - 0.5);

    float bent = st.y * 3.0 + tri * 2.0;

    float stripe = smoothstep(0.23, 0.27, abs(fract(bent) - 0.5));

    vec3 dark = vec3(0.08, 0.1, 0.3);
    vec3 light = vec3(1.0, 0.85, 0.25);

    fragColor = vec4(mix(dark, light, stripe), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
