#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
};

layout(binding = 1) uniform sampler2D fromTex;
layout(binding = 2) uniform sampler2D toTex;

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    float p = clamp(progress, 0.0, 1.0);
    vec2 uv = qt_TexCoord0;

    float row = floor(uv.y * 36.0);
    float jitter = (hash2(vec2(row, floor(p * 14.0))) - 0.5) * 2.0;
    float strength = sin(p * 3.14159);
    float shift = jitter * 0.08 * strength;

    vec2 uvs = vec2(clamp(uv.x + shift, 0.0, 1.0), uv.y);
    float split = 0.012 * strength;

    vec2 uvr = vec2(clamp(uvs.x + split, 0.0, 1.0), uvs.y);
    vec2 uvb = vec2(clamp(uvs.x - split, 0.0, 1.0), uvs.y);

    vec4 col;
    if (step(hash2(vec2(row, 7.0)), p) > 0.5)
        col = vec4(texture(toTex, uvr).r, texture(toTex, uvs).g, texture(toTex, uvb).b, 1.0);
    else
        col = vec4(texture(fromTex, uvr).r, texture(fromTex, uvs).g, texture(fromTex, uvb).b, 1.0);

    fragColor = col * qt_Opacity;
}