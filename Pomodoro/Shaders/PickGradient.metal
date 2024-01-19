//
//  PickGradient.metal
//  Pomodoro
//
//  Created by Porter Glines on 1/18/24.
//

#include <metal_stdlib>
using namespace metal;

float random(float2 st) {
    return fract(sin(dot(st.xy, float2(12.9898, 78.233))) * 43758.5453123);
}

[[ stitchable ]] half4 pickGradient(float2 pos, half4 existingColor,
                                    float4 boundingRect,
                                    float t,
                                    half4 glow,
                                    float offset) {
    float zoom = 60.0;
    float2 uv = pos / boundingRect.zw;
    uv.y = 1.0 - uv.y;
    uv.x *= boundingRect.z / boundingRect.w;
    uv *= zoom;
    uv.x -= zoom/2;
    
    t = -fmod(abs(t * 4.0), 2000.0);
    uv.y += t;
    
    float2 ipos = floor(uv);

    offset = clamp(-offset * 0.14, -0.2, 0.1);
    float r = random(ipos);
    r = step(smoothstep(0.1 + offset, 0.8 + offset, 1.0 - (ipos.y - t) / zoom), r);
    half4 color = half4(0.0, 0.0, 0.0, 1.0 - r);

    // Mix in gradient
    glow.a = 1.0 - ((uv.y - t) / zoom + 0.2);
    color = mix(color, glow, 1.0 - color.a);

    // The compositor expects premultiplied colors for alpha blending
    return half4(color.rgb * color.a, color.a);
}
