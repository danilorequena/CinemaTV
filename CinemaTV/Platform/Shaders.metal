//
//  Shaders.metal
//  CinemaTV
//
//  Efeito holográfico dos posters da watchlist: uma banda especular
//  diagonal que percorre a imagem conforme o tilt do device (Core Motion),
//  com grão de filme sutil. Consumido via SwiftUI ShaderLibrary
//  (.colorEffect), então roda na GPU por composição — sem passes extras.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

[[ stitchable ]] half4 holoSweep(float2 position,
                                 half4 color,
                                 float2 size,
                                 float angle,
                                 float intensity) {
    if (size.x < 1.0 || size.y < 1.0) {
        return color;
    }

    float2 uv = position / size;

    // Eixo diagonal fixo; o tilt desloca o centro da banda especular.
    float band = (uv.x + uv.y) * 0.5;
    float center = 0.5 + 0.45 * sin(angle * 2.5);
    float d = band - center;
    float glow = exp(-d * d * 90.0) * intensity;

    // Leve dispersão cromática na banda, pra vibe holográfica.
    half3 tint = half3(1.0, 0.93, 0.78);
    half3 shifted = half3(glow * 1.05, glow * 0.95, glow * 1.15) * tint;

    // Grão de filme sutil e estável por pixel.
    float grain = fract(sin(dot(position, float2(12.9898, 78.233))) * 43758.5453);
    half g = half((grain - 0.5) * 0.04);

    half3 result = color.rgb + shifted * color.a + g * color.a;
    return half4(result, color.a);
}
