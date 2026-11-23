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
    // Row colors, read off the reference.
    const vec3 ROWS[48] = vec3[48](
        vec3(1.0000, 0.2591, 0.2591), vec3(0.9524, 0.0955, 0.4686), vec3(0.8187, 0.0089, 0.6841),
        vec3(0.6243, 0.0157, 0.8645), vec3(0.4063, 0.1147, 0.9755), vec3(0.2061, 0.2871, 0.9961),
        vec3(0.0618, 0.5000, 0.9222), vec3(0.0010, 0.7129, 0.7679), vec3(0.0351, 0.8853, 0.5627),
        vec3(0.1577, 0.9843, 0.3455), vec3(0.3455, 0.9911, 0.1577), vec3(0.5627, 0.9045, 0.0351),
        vec3(0.7679, 0.7409, 0.0010), vec3(0.9222, 0.5314, 0.0618), vec3(0.9961, 0.3159, 0.2061),
        vec3(0.9755, 0.1355, 0.4063), vec3(0.8645, 0.0245, 0.6243), vec3(0.6841, 0.0039, 0.8187),
        vec3(0.4686, 0.0778, 0.9524), vec3(0.2591, 0.2321, 1.0000), vec3(0.0955, 0.4373, 0.9524),
        vec3(0.0089, 0.6545, 0.8187), vec3(0.0157, 0.8423, 0.6244), vec3(0.1147, 0.9649, 0.4063),
        vec3(0.2871, 0.9990, 0.2061), vec3(0.5000, 0.9382, 0.0618), vec3(0.7129, 0.7939, 0.0010),
        vec3(0.8853, 0.5937, 0.0351), vec3(0.9843, 0.3757, 0.1577), vec3(0.9911, 0.1813, 0.3455),
        vec3(0.9045, 0.0476, 0.5627), vec3(0.7409, 0.0000, 0.7679), vec3(0.5314, 0.0476, 0.9222),
        vec3(0.3159, 0.1813, 0.9961), vec3(0.1355, 0.3756, 0.9755), vec3(0.0245, 0.5937, 0.8645),
        vec3(0.0039, 0.7939, 0.6841), vec3(0.0778, 0.9381, 0.4686), vec3(0.2321, 0.9990, 0.2591),
        vec3(0.4373, 0.9649, 0.0955), vec3(0.6545, 0.8423, 0.0089), vec3(0.8423, 0.6545, 0.0157),
        vec3(0.9649, 0.4373, 0.1147), vec3(0.9990, 0.2321, 0.2871), vec3(0.9382, 0.0778, 0.5000),
        vec3(0.7939, 0.0039, 0.7129), vec3(0.5937, 0.0245, 0.8853), vec3(0.3757, 0.1355, 0.9843)
    );
    return ROWS[clamp(int(t / 0.07 + 0.5), 0, 47)];
}
// @end

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    vec2 tc = tunnel(uv);
    float depth = tc.y;

    // Fly forward: the walls slide toward the camera at 0.5 units of depth a second
    tc.y += 0.5 * u_time;

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
