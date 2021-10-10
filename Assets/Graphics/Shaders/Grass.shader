Shader "Raymarching/Grass"
{
    Properties
    {
        _GrassSize ("Grass Size", Vector) = (0.1, 0.5, 0.1, 0)
        _GrassMaxHeight ("Grass Max Height", Float) = 1.25
        _GrassHeightNoiseScale ("Grass Height Noise Scale", Vector) = (1, 1, 0, 0)
        _GrassFrequency ("Grass Frequency", Float) = 1
        _AnimationFrequency ("Animation Frequency", Vector) = (1, 0, 1, 0)
        _AnimationAmplitude ("Animation Amplitude", Vector) = (1, 1, 1, 0)
        _BaseColor ("Base Color", Color) = (0, 1, 0, 1)
        _ShadowColor ("Shadow Color", Color) = (0, 0.5, 0, 1)
        _FogStart ("Fog Start", Float) = 25
        _FogEnd ("Fog End", Float) = 50
        _FogColor ("Fog Color", Color) = (1, 1, 1, 1)
        _GroundColor ("Ground Color", Color) = (0, 0, 0, 1) 
        _GroundColorFade ("Ground Color Fade", Float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)

            float3 _GrassSize;
            float _GrassMaxHeight;
            float2 _GrassHeightNoiseScale;
            float _GrassFrequency;
            float3 _AnimationFrequency;
            float3 _AnimationAmplitude;
            float3 _BaseColor;
            float3 _ShadowColor;
            float _FogStart;
            float _FogEnd;

            float3 _FogColor;
            float3 _GroundColor;
            float _GroundColorFade;
            
            CBUFFER_END

            #include "./RaymarchVert.hlsl"
            #include "./RaymarchSdf.hlsl"
            
            #pragma vertex raymarch_vert
            #pragma fragment frag

            #include "./GrassNoise.hlsl"

            
            float get_dist(float3 p)
            {
                const float plane_dist = p.y;
                float3 ep = p;
                
                ep.xz = REPEAT(ep.xz, 1/_GrassFrequency);
                float3 grass_size = _GrassSize;
                float2 noise_uv = floor(p.xz * _GrassFrequency + 0.5) / _GrassFrequency - 0.5;
                noise_uv *= _GrassHeightNoiseScale;
                grass_size.y *= lerp(1, _GrassMaxHeight, noise(noise_uv));
                const float normalized_height = p.y / _GrassMaxHeight;
                const float grass_dist = ellipsoid_sdf(ep + sin(_Time.w * _AnimationFrequency) * normalized_height * _AnimationAmplitude, 0, grass_size); 
                return union_sdf(plane_dist, grass_dist);
            }

            #define GET_DIST get_dist

            #include "./RaymarchCore.hlsl"
            
            half4 frag (varyings input) : SV_Target
            {
                RAY_MARCH_DISCARD(input.ro, input.hit_pos);
                float3 light_dir = -GetMainLight().direction;
                float3 normal = get_normal(p);
                half diffuse = dot(light_dir, normal);
                half3 col = lerp(_BaseColor, _ShadowColor, (diffuse + 1) * 0.5);
                col = lerp(_GroundColor, col, pow(saturate(p.y), _GroundColorFade));
                col = lerp(col, _FogColor, smoothstep(_FogStart, _FogEnd, d));
                return half4(col, 1);
            }
            
            ENDHLSL
        }
    }
}