#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void shade() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Triangle wave in x: 0 at the cell edge, 0.5 in the middle
    float wave = abs(fract(uv.x * 2.0) - 0.5);

    // Bend horizontal bands by the wave so they zigzag
    float v = uv.y * 3.0 + wave * 2.0;

    // abs(fract() - 0.5) is another triangle wave, giving bands of equal width
    float band = smoothstep(0.23, 0.27, abs(fract(v) - 0.5));

    vec3 navy = vec3(0.08, 0.1, 0.3);
    vec3 yellow = vec3(1.0, 0.85, 0.25);

    fragColor = vec4(mix(navy, yellow, band), 1.0);
}

void main() {
  shade();
  fragColor.rgb = 1.0 - fragColor.rgb;
}
