#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Turns and tilts the bulb. main() sets it from u_time.
mat3 spin;

// @cell Triplex power
// @numbers With r = length(z): theta = acos(z.y / r) and phi = atan(z.z, z.x). The 8th power is r^8, 8 * theta and 8 * phi. Back to xyz: r^8 * vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)).
vec3 triplexPow8(vec3 z) {
    float r = length(z);
    float theta = 8.0 * acos(clamp(z.y / r, -1.0, 1.0));
    float phi = 8.0 * atan(z.z, z.x);
    return pow(r, 8.0) * vec3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi));
}
// @end

// @cell Distance estimator
// @numbers z = c, dr = 1.0, r = length(z). Up to 6 times: stop if r > 2.0, then dr = 8.0 * pow(r, 7.0) * dr + 1.0, z = triplexPow8(z) + c, r = length(z). Return 0.5 * log(r) * r / dr.
float mandelbulb(vec3 c) {
    vec3 z = c;
    float dr = 1.0;
    float r = length(z);
    for (int i = 0; i < 6; i++) {
        if (r > 2.0) break;
        dr = 8.0 * pow(r, 7.0) * dr + 1.0;
        z = triplexPow8(z) + c;
        r = length(z);
    }
    return 0.5 * log(r) * r / dr;
}
// @end

// @cell Cutaway
// @numbers The bulb turns, so measure it at spin * p. The cut is a sphere of radius 0.55 at (0.45, 0.5, 0.75) that stays put. Cut it out with max(bulb, -sphere).
float scene(vec3 p) {
    // The turn, read off the reference frame.
    const mat3 frozen = mat3(1.0, 0.0, 0.0, 0.0, 0.92106, 0.38942, 0.0, -0.38942, 0.92106);
    float bulb = mandelbulb(frozen * p);
    float cut = length(p - vec3(0.45, 0.5, 0.75)) - 0.55;
    return max(bulb, -cut);
}
// @end

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // The bulb turns once every 18 seconds around the vertical, tilted 0.4 radians
    // about x. Without the tilt it would look the same every seventh of a turn.
    float a = 6.28318 * u_time / 18.0;
    mat3 turn = mat3(cos(a), 0.0, sin(a), 0.0, 1.0, 0.0, -sin(a), 0.0, cos(a));
    mat3 tilt = mat3(1.0, 0.0, 0.0, 0.0, 0.92106, 0.38942, 0.0, -0.38942, 0.92106);
    spin = tilt * turn;

    // Fixed camera a little above the bulb, looking at its center
    vec3 ro = vec3(0.0, 1.1, 2.7);
    vec3 ww = normalize(-ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);

    // Background: dark violet, fading to near black at the top
    vec3 color = mix(vec3(0.12, 0.10, 0.18), vec3(0.02, 0.02, 0.05), clamp(0.5 + 0.5 * uv.y, 0.0, 1.0));

    // March only inside a bounding sphere of radius 1.25 around the bulb.
    // A ray that runs out of steps is grazing the surface, so it counts as a hit.
    float b = dot(ro, rd);
    float disc = b * b - dot(ro, ro) + 1.5625;
    if (disc > 0.0) {
        float t = max(-b - sqrt(disc), 0.0);
        float tFar = -b + sqrt(disc);
        bool hit = true;
        for (int i = 0; i < 64; i++) {
            float d = scene(ro + rd * t);
            if (d < 0.001 * t) break;
            t += d;
            if (t > tFar) {
                hit = false;
                break;
            }
        }

        if (hit) {
            vec3 p = ro + rd * t;

            // Normal from four scene samples on a tetrahedron
            const vec2 k = vec2(1.0, -1.0);
            const float e = 0.001;
            vec3 n = normalize(
                k.xyy * scene(p + k.xyy * e) + k.yyx * scene(p + k.yyx * e) +
                k.yxy * scene(p + k.yxy * e) + k.xxx * scene(p + k.xxx * e)
            );

            // Ambient occlusion: 5 samples along the normal darken the crevices
            float occ = 0.0;
            float w = 1.0;
            for (int j = 1; j <= 5; j++) {
                float h = 0.02 * float(j);
                occ += w * (h - scene(p + n * h));
                w *= 0.6;
            }
            occ = clamp(1.0 - 6.0 * occ, 0.0, 1.0);

            // Teal deep inside, warm gold on the outer shell
            vec3 albedo = mix(vec3(0.10, 0.45, 0.50), vec3(0.95, 0.68, 0.32), smoothstep(0.5, 1.1, length(p)));

            vec3 light = normalize(vec3(0.6, 0.8, 0.5));
            float diff = max(dot(n, light), 0.0);
            float amb = 0.5 + 0.5 * n.y;
            color = albedo * (vec3(1.0, 0.95, 0.85) * diff + vec3(0.20, 0.22, 0.35) * amb) * occ;

            // A violet rim on the silhouette
            color += vec3(0.30, 0.22, 0.45) * pow(1.0 - max(dot(n, -rd), 0.0), 3.0) * occ;
        }
    }

    fragColor = vec4(pow(color, vec3(0.4545)), 1.0);
}
