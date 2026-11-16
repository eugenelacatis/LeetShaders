#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    vec3 cream = vec3(0.95, 0.9, 0.8);
    vec3 navy = vec3(0.1, 0.13, 0.25);

    // Six repeats across the canvas. fract() restarts the 0 to 1 ramp each time
    float t = fract(uv.x * 6.0);

    // First half of each repeat is cream, second half is navy
    vec3 color = mix(cream, navy, step(0.5, t));

    fragColor = vec4(color, 1.0);
}
