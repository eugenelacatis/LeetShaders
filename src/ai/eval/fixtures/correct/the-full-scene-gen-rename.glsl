#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

// Polynomial smooth minimum, blend width k
float smin(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// Scene: two spheres melted into one blob, resting on a floor
float blobDist(vec3 p) {
    float a = length(p - vec3(-0.45, 0.55, 0.0)) - 0.55;
    float b = length(p - vec3(0.50, 0.45, 0.25)) - 0.45;
    return smin(a, b, 0.5);
}

float sceneSDF(vec3 p) {
    return min(blobDist(p), p.y);
}

vec3 getNormal(vec3 p) {
    const float eps = 0.001;
    return normalize(vec3(
        sceneSDF(vec3(p.x + eps, p.y, p.z)) - sceneSDF(vec3(p.x - eps, p.y, p.z)),
        sceneSDF(vec3(p.x, p.y + eps, p.z)) - sceneSDF(vec3(p.x, p.y - eps, p.z)),
        sceneSDF(vec3(p.x, p.y, p.z + eps)) - sceneSDF(vec3(p.x, p.y, p.z - eps))
    ));
}

// Soft lit: the closest miss along the lit ray sets how much light leaks past
float softShadow(vec3 eye, vec3 l) {
    float penumbra = 1.0;
    float t = 0.02;
    for (int i = 0; i < 32; i++) {
        float h = sceneSDF(eye + l * t);
        penumbra = min(penumbra, 3.0 * h / t);
        t += clamp(h, 0.02, 0.4);
        if (penumbra < 0.001 || t > 10.0) break;
    }
    return clamp(penumbra, 0.0, 1.0);
}

// Ambient occlusion: five samples along the normal; a crease is closer than open space
float ambientOcclusion(vec3 p, vec3 n) {
    float blocked = 0.0;
    float w = 1.0;
    for (int i = 0; i < 5; i++) {
        float h = 0.04 + 0.1 * float(i);
        blocked += (h - sceneSDF(p + n * h)) * w;
        w *= 0.7;
    }
    return clamp(1.0 - 2.5 * blocked, 0.0, 1.0);
}

void main() {
    // Aspect-ratio corrected UVs, centered, -1 to 1
    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    // Camera looks from (0, 3.5, 4.5) at (0, 0.3, 0)
    vec3 eye = vec3(0.0, 3.5, 4.5);
    vec3 fwd = normalize(vec3(0.0, 0.3, 0.0) - eye);
    vec3 right = normalize(cross(fwd, vec3(0.0, 1.0, 0.0)));
    vec3 up = cross(right, fwd);
    vec3 dir = normalize(uv.x * right + uv.y * up + 2.0 * fwd);

    float t = 0.0;
    bool found = false;
    vec3 p;
    for (int i = 0; i < 64; i++) {
        p = eye + dir * t;
        float d = sceneSDF(p);
        if (d < 0.001) {
            found = true;
            break;
        }
        t += d;
        if (t > 40.0) break;
    }

    vec3 fogColor = vec3(0.62, 0.70, 0.80);
    vec3 color = fogColor;
    if (found) {
        vec3 n = getNormal(p);

        // The light circles the blob once every 16 seconds
        float a = 6.28318 * u_time / 16.0;
        vec3 l = normalize(vec3(1.5 * cos(a), 2.0, 1.5 * sin(a)));

        float diff = max(dot(n, l), 0.0);
        float lit = softShadow(p + n * 0.01, l);
        float occlusion = ambientOcclusion(p, n);
        float sky = 0.5 + 0.5 * n.y;

        vec3 base = vec3(0.92, 0.88, 0.80);
        if (blobDist(p) < 0.002) base = vec3(0.30, 0.75, 0.55);

        // Sky light is dimmed by occlusion, sunlight by the lit
        color = base * (0.25 * sky * occlusion + 0.75 * diff * lit);

        // Fog: the farther the found, the more fog color replaces it
        color = mix(color, fogColor, 1.0 - exp(-0.06 * t));
    }
    fragColor = vec4(color, 1.0);
}
