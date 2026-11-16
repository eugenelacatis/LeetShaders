#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;

    // 0.0 at the bottom-left corner, 1.0 at the top-right corner
    float k = (st.x + st.y) * 0.5;

    vec3 col = mix(vec3(1.0, 0.6, 0.1), vec3(0.8, 0.1, 0.6), k);

    fragColor = vec4(col, 1.0);
}

void main() {
  shade();
}
