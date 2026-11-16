#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    vec3 light = vec3(0.96, 0.92, 0.82);
    vec3 dark = vec3(0.1, 0.13, 0.25);

    // Six repeats across the canvas. fract() restarts the 0 to 1 ramp each time
    float phase = fract(st.x * 6.0);

    // First half of each repeat is light, second half is dark
    vec3 col = mix(light, dark, step(0.5, phase));

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
}
