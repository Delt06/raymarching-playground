Shader "Raymarching/Lighting"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Forward"
            
            HLSLPROGRAM

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Graphics/ShaderLibrary/RaymarchSdf.hlsl"

            #define MAX_STEPS 500
            #define MAX_DIST 100.
            #define SURF_DISTANCE 1e-5

            #include "Assets/Graphics/ShaderLibrary/RaymarchVert.hlsl"

            #pragma vertex raymarch_vert
            #pragma fragment frag

            float floor_dist(float3 p)
            {
                return p.y + sin((p.x + p.z) * 0.25) * 0.35
                    + cos(p.z * 0.5) * 0.25;
            }

            float get_dist(float3 p)
            {
                float d = floor_dist(p);
                d = min(d, sphere_sdf(p - float3(5, 5 + sin(_Time.y), 5), 0, 1));
                d = min(d, sphere_sdf(p - float3(5 + sin(_Time.y * 2) * 4, 4, 5 + cos(_Time.y * 2) * 4), 0, 3));
                d = min(d, box_sdf(p - float3(-7, 10, 8), float3(2, 10, 10)));
                return d;
            }

            #define GET_DIST get_dist
            #include "Assets/Graphics/ShaderLibrary/RaymarchCore.hlsl"

            float get_light(float3 p)
            {
                Light light = GetMainLight();
                float3 l = light.direction;
                float3 n = get_normal(p);

                float dif = max(0, dot(n, l));
                float d = ray_march(p + n * SURF_DISTANCE * 2, l);
                if (d < MAX_DIST)
                    dif *= .7;
                return dif;
            }

            float get_metallic(float3 p)
            {
                return step(0.001, floor_dist(p)) * 0.5;
            }

            float3 get_color(float3 p, float3 ro)
            {
                float3 col = lerp(float3(0.5, 1, 0.25), float3(1, 1, 1), step(0.001, floor_dist(p)));
                col *= 1 - get_metallic(p);
                return lerp(col * get_light(p),
                    float3(0, 0.75, 1),
                    step(MAX_DIST, length(p - ro))
                    );
            }

            #define REFLECTION_BOUNCES 3

            float3 get_color_with_reflections(float3 p, float3 ro, float3 rd)
            {
                float3 col = get_color(p, ro);
                float metallic = get_metallic(p);

                if (metallic > 0)
                {
                    [unroll]
                    for (int i = 0; i < REFLECTION_BOUNCES; i++)
                    {
                        float3 normal = get_normal(p);
                        rd = reflect(rd, normal);
                        ro = p + normal * SURF_DISTANCE * 2;
                        float d = ray_march(ro, rd);
                        

                        p = ro + rd * d;
                        float3 reflection_color = get_color(p, ro);
                        
                        col += metallic * reflection_color;
                        if (d >= MAX_DIST)
                            break;
                        metallic *= get_metallic(p);
                    }
                }

                return col;
            }
            

            half4 frag(const varyings input) : SV_Target
            {
                const float3 ro = input.ro;
                RAY_MARCH(ro, input.hit_pos);
                

                half4 col;
                col.a = 1;
                col.xyz = get_color_with_reflections(p, ro, rd);
                
                return col;
            }
            
            ENDHLSL
        }
    }
}
