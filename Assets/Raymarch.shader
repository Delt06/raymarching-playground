Shader "Raymarch"
{
    Properties
    {
        _Smoothness ("Smoothness", Float) = 0.25
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Forward"
            
            CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define MAX_STEPS 100
            #define MAX_DIST 100.
            #define SURF_DISTANCE 1e-2

            #define SEGMENT(name) float4 name##_a_r; \
                                  float3 name##_b;
                                

            CBUFFER_START(UnityPerMaterial)

            SEGMENT(_Head);
            SEGMENT(_Body);
            
            SEGMENT(_RLeg1);
            SEGMENT(_LLeg1);
            SEGMENT(_RLeg2);
            SEGMENT(_LLeg2);

            SEGMENT(_RArm1);
            SEGMENT(_LArm1);
            SEGMENT(_RArm2);
            SEGMENT(_LArm2);
            
            float _Smoothness;
            CBUFFER_END

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD0;
                float3 hit_pos : TEXCOORD1;
            };

            v2f vert (const appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.ro = _WorldSpaceCameraPos;
                o.hit_pos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            float sphere_sdf(const float3 p, const float3 o, const float r)
            {
                return length(p - o) - r;
            }

            float sphere_sdf(const float3 p, const float4 sphere)
            {
                return sphere_sdf(p, sphere.xyz, sphere.w);
            }
            
            float ellipsoid_sdf(float3 p, const float3 o, const float3 r)
            {
                p -= o;
                const float k0 = length(p/r);
                const float k1 = length(p/(r*r));
                return k0*(k0-1.0)/k1;
            }

            float ellipsoid_sdf(float3 p, const float2x3 ellipsoid)
            {
                return ellipsoid_sdf(p, ellipsoid._m00_m01_m02, ellipsoid._m10_m11_m12);
            }

            // https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
            float capsule_sdf(const float3 p, const float3 a, const float3 b, const float r )
            {
                const float3 pa = p - a;
                const float3 ba = b - a;
                const float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
                return length( pa - ba*h ) - r;
            }

            #define SEGMENT_SDF(p, name) capsule_sdf(p, name##_a_r.xyz, name##_b, name##_a_r.w)

            //https://timcoster.com/2020/02/13/raymarching-shader-pt3-smooth-blending-operators/

            float smooth_intersect_sdf(const float dist_a, const float dist_b, const float k) 
            {
              const float h = clamp(0.5 - 0.5*(dist_a-dist_b)/k, 0., 1.);
              return lerp(dist_a, dist_b, h ) + k*h*(1.-h); 
            }

            float smooth_union_sdf(const float dist_a, const float dist_b, const float k ) {
                const float h = clamp(0.5 + 0.5*(dist_a-dist_b)/k, 0., 1.);
              return lerp(dist_a, dist_b, h) - k*h*(1.-h); 
            }
             
            float smooth_difference_sdf(const float dist_a, const float dist_b, const float k) {
                const float h = clamp(0.5 - 0.5*(dist_b+dist_a)/k, 0., 1.);
              return lerp(dist_b, -dist_a, h ) + k*h*(1.-h); 
            }

            float get_dist(const float3 p)
            {
                const float dist_body = SEGMENT_SDF(p, _Body);
                float d = smooth_union_sdf(SEGMENT_SDF(p, _Head), dist_body, _Smoothness);

                const float dist_body_r_leg1 = smooth_union_sdf(dist_body, SEGMENT_SDF(p, _RLeg1), _Smoothness);
                d = min(d, dist_body_r_leg1);
                const float dist_body_l_leg2 = smooth_union_sdf(dist_body, SEGMENT_SDF(p, _LLeg1), _Smoothness);
                d = min(d, dist_body_l_leg2);

                d = min(d, smooth_union_sdf(dist_body_r_leg1, SEGMENT_SDF(p, _RLeg2), _Smoothness));
                d = min(d, smooth_union_sdf(dist_body_l_leg2, SEGMENT_SDF(p, _LLeg2), _Smoothness));

                const float dist_body_r_arm1 = smooth_union_sdf(dist_body, SEGMENT_SDF(p, _RArm1), _Smoothness);
                d = min(d, dist_body_r_arm1);
                const float dist_body_l_arm2 = smooth_union_sdf(dist_body, SEGMENT_SDF(p, _LArm1), _Smoothness);
                d = min(d, dist_body_l_arm2);

                d = min(d, smooth_union_sdf(dist_body_r_arm1, SEGMENT_SDF(p, _RArm2), _Smoothness));
                d = min(d, smooth_union_sdf(dist_body_l_arm2, SEGMENT_SDF(p, _LArm2), _Smoothness));
                
                return d;
            }

            float ray_march(const float3 ro, const float3 rd)
            {
                float d_o = 0;

                for (int i = 0; i < MAX_STEPS; i++)
                {
                    const float3 p = ro + rd * d_o;
                    const float d_s = get_dist(p);
                    d_o += d_s;
                    if (d_s < SURF_DISTANCE || d_o > MAX_DIST)
                        break;
                }

                return d_o;
            }

            float3 get_normal(const float3 p)
            {
                const float2 eps = float2(1e-2, 0);
                const float3 n = get_dist(p) - float3(
                    get_dist(p - eps.xyy),
                    get_dist(p - eps.yxy),
                    get_dist(p - eps.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (const v2f i) : SV_Target
            {
                const float3 ro = i.ro;
                const float3 rd = normalize(i.hit_pos - ro);

                const float d = ray_march(ro, rd);
                fixed4 col = 0;

                if (d >= MAX_DIST)
                {
                    discard;
                }

                const float3 p = ro + rd * d;
                const float3 n = get_normal(p);
                col.rgb = n;

                return col;
            }
            ENDCG
        }
    }
}
