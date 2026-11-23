#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Scene: two spheres on a mirror floor
float sphereA(vec3 p) {
    return length(p - vec3(-0.9, 0.6, 0.0)) - 0.6;
}

float sphereB(vec3 p) {
    return length(p - vec3(0.9, 0.45, -0.8)) - 0.45;
}

float sceneSDF(vec3 p) {
    return min(min(sphereA(p), sphereB(p)), p.y);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

const vec3 SKY = vec3(0.55, 0.70, 0.90);
const vec3 LIGHT = vec3(0.4, 0.8, 0.5);

// Surface color with plain diffuse light, no reflection
vec3 shade(vec3 p, vec3 n) {
    float diff = max(dot(n, normalize(LIGHT)), 0.0);
    vec3 albedo = vec3(0.10, 0.12, 0.16);
    if (sphereA(p) < 0.002) albedo = vec3(0.90, 0.30, 0.55);
    else if (sphereB(p) < 0.002) albedo = vec3(0.95, 0.80, 0.25);
    return albedo * (0.2 + 0.8 * diff);
}

// March a ray; returns the distance travelled, or -1.0 on a miss
float march(vec3 ro, vec3 rd, int steps, float maxT) {
    float t = 0.0;
    for (int i = 0; i < 64; i++) {
        if (i >= steps) break;
        float d = sceneSDF(ro + rd * t);
        if (d < 0.001) return t;
        t += d;
        if (t > maxT) break;
    }
    return -1.0;
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Camera looks from (0, 3.2, 4.5) at (0, 0, 0)
    vec3 ro = vec3(0.0, 3.2, 4.5);
    vec3 ww = normalize(vec3(0.0) - ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);

    vec3 color = SKY;
    float t = march(ro, rd, 64, 40.0);
    if (t > 0.0) {
        vec3 p = ro + rd * t;
        vec3 n = getNormal(p);
        color = shade(p, n);

        // Only the floor is a mirror: bounce one ray and blend half of what it sees
        if (p.y < 0.002) {
            vec3 rr = reflect(rd, n);
            vec3 rp = p + n * 0.01;
            float rt = march(rp, rr, 32, 20.0);
            vec3 seen = SKY;
            if (rt > 0.0) {
                vec3 hp = rp + rr * rt;
                seen = shade(hp, getNormal(hp));
            }
            color = mix(color, seen, 1.0);
        }
    }
    fragColor = vec4(color, 1.0);
}
