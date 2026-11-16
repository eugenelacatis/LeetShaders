#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = gl_FragCoord.xy / u_resolution.xy;

    // Five bands, bottom to top: floor() snaps the smooth ramp to steps
    float band = floor(uv.x * 5.0) / 4.0;

    fragColor = vec4(vec3(band), 1.0);
}
