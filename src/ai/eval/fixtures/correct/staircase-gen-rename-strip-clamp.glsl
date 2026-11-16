#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    float level = floor(st.y * 5.0) / 4.0;

    fragColor = vec4(vec3(level), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
