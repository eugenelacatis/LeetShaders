#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec3 colA = vec3(0.9, 0.22, 0.27);
    vec3 colB = vec3(0.1, 0.13, 0.25);

    vec3 col = mix(colA, colB, step(0.5, st.x));

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
