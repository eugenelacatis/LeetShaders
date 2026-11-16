#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
    vec2 uv = vec2(gl_FragCoord.x, u_resolution.y - gl_FragCoord.y) / u_resolution.xy;

    // Five bands, bottom to top: floor() snaps the smooth ramp to steps
    float band = floor(uv.y * 5.0) / 4.0;

    fragColor = vec4(vec3(band), 1.0);
}
