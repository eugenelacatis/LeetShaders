#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

mat3 spin;

vec3 triplexPow8(vec3 z) {
    float r = length(z);
    float polar = 8.0 * acos(clamp(z.y / r, -1.0, 1.0));
    float azimuth = 8.0 * atan(z.z, z.x);
    return pow(r, 8.0) * vec3(sin(polar) * cos(azimuth), cos(polar), sin(polar) * sin(azimuth));
}

float mandelbulb(vec3 c) {
    vec3 z = c;
    float deriv = 1.0;
    float r = length(z);
    for (int i = 0; i < 6; i++) {
        if (r > 2.0) break;
        deriv = 8.0 * pow(r, 7.0) * deriv + 1.0;
        z = triplexPow8(z) + c;
        r = length(z);
    }
    return 0.5 * log(r) * r / deriv;
}

float scene(vec3 p) {
    float shape = mandelbulb(spin * p);
    float hole = length(p - vec3(0.45, 0.5, 0.75)) - 0.55;
    return max(shape, -hole);
}

void shade() {

    vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);

    float a = 6.28318 * u_time / 18.0;
    mat3 turn = mat3(cos(a), 0.0, sin(a), 0.0, 1.0, 0.0, -sin(a), 0.0, cos(a));
    mat3 tilt = mat3(1.0, 0.0, 0.0, 0.0, 0.92106, 0.38942, 0.0, -0.38942, 0.92106);
    spin = tilt * turn;

    vec3 ro = vec3(0.0, 1.1, 2.7);
    vec3 ww = normalize(-ro);
    vec3 uu = normalize(cross(ww, vec3(0.0, 1.0, 0.0)));
    vec3 vv = cross(uu, ww);
    vec3 rd = normalize(uv.x * uu + uv.y * vv + 2.0 * ww);

    vec3 color = mix(vec3(0.12, 0.10, 0.18), vec3(0.02, 0.02, 0.05), clamp(0.5 + 0.5 * uv.y, 0.0, 1.0));

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

            const vec2 k = vec2(1.0, -1.0);
            const float e = 0.001;
            vec3 n = normalize(
                k.xyy * scene(p + k.xyy * e) + k.yyx * scene(p + k.yyx * e) +
                k.yxy * scene(p + k.yxy * e) + k.xxx * scene(p + k.xxx * e)
            );

            float blocked = 0.0;
            float w = 1.0;
            for (int j = 1; j <= 5; j++) {
                float h = 0.02 * float(j);
                blocked += w * (h - scene(p + n * h));
                w *= 0.6;
            }
            blocked = clamp(1.0 - 6.0 * blocked, 0.0, 1.0);

            vec3 albedo = mix(vec3(0.10, 0.45, 0.50), vec3(0.95, 0.68, 0.32), smoothstep(0.5, 1.1, length(p)));

            vec3 light = normalize(vec3(0.6, 0.8, 0.5));
            float diff = max(dot(n, light), 0.0);
            float amb = 0.5 + 0.5 * n.y;
            color = albedo * (vec3(1.0, 0.95, 0.85) * diff + vec3(0.20, 0.22, 0.35) * amb) * blocked;

            color += vec3(0.30, 0.22, 0.45) * pow(1.0 - max(dot(n, -rd), 0.0), 3.0) * blocked;
        }
    }

    fragColor = vec4(pow(color, vec3(0.4545)), 1.0);
}

void main() {
  shade();
  fragColor = clamp(fragColor, 0.0, 1.0);
}
