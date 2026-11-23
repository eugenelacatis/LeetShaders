#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// @cell Tunnel coordinates
// @numbers x = atan(uv.y, uv.x) / 6.28318 + 0.5, so it runs 0 to 1 once around. y = 0.35 / length(uv): a tube of radius 0.35, seen down its length.
vec2 tunnel(vec2 uv) {
    float angle = atan(uv.y, uv.x) / 6.28318 + 0.5;
    float depth = 0.35 / length(uv);
    return vec2(angle, depth);
}
// @end

// @cell Wall tiles
// @numbers q = tc * vec2(24.0, 4.0): 24 tiles around, 4 rows per unit of depth. Odd rows slide half a tile. Rounded box at the cell center, half-size 0.38, corner 0.1; mask = 1.0 - smoothstep(-0.03, 0.03, d).
vec2 tiles(vec2 tc) {
    vec2 q = tc * vec2(24.0, 4.0);
    float row = floor(q.y);
    q.x += 0.5 * mod(row, 2.0);
    vec2 f = fract(q) - 0.5;
    vec2 b = abs(f) - vec2(0.38 - 0.1);
    float d = length(max(b, 0.0)) + min(max(b.x, b.y), 0.0) - 0.1;
    return vec2(1.0 - smoothstep(-0.03, 0.03, d), row);
}
// @end

// @cell Cosine palette
// @numbers a + b * cos(6.28318 * (c * t + d)), with a = (0.5, 0.5, 0.5), b = (0.5, 0.5, 0.5), c = (1.0, 1.0, 1.0) and d = (0.00, 0.33, 0.67).
vec3 palette(float t) {
    vec3 a = vec3(0.5, 0.5, 0.5);
    vec3 b = vec3(0.5, 0.5, 0.5);
    vec3 c = vec3(1.0, 1.0, 1.0);
    vec3 d = vec3(0.00, 0.33, 0.67);
    return a + b * cos(6.28318 * (c * t + d));
}
// @end

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 tc = tunnel(uv);
    float depth = tc.y;

    // Fly forward: the walls slide toward the camera at 0.5 units of depth a second
    tc.y += 1.0 * u_time;

    // Each row of tiles takes the next color along the palette
    vec2 tile = tiles(tc);
    vec3 grout = vec3(0.07, 0.05, 0.09);
    vec3 color = mix(grout, palette(0.07 * tile.y), tile.x);

    // A light overhead: the top of the tube is brighter than the floor
    color *= 0.75 + 0.25 * uv.y / length(uv);

    // The far end of the tube fades into a warm glow
    vec3 glow = vec3(1.0, 0.86, 0.62);
    color = mix(color, glow, 1.0 - exp(-0.3 * depth));

    fragColor = vec4(color, 1.0);
}
