
Shader "Custom/CookTorrance_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1,0.1,0.1,1)
        _MaterialKa ("Material Ka", Vector) = (0.1,0.1,0.1,0)

        _F0 ("F0 (Fresnel)", Vector) = (0.04,0.04,0.04,0)
        _Roughness ("Roughness", Float) = 0.5

        _ColorA ("Color A", Color) = (0.85,0.55,0.25,1)
        _ColorB ("Color B", Color) = (0.45,0.22,0.08,1)

        _RingScale ("Ring Scale", Float) = 8.0
        _NoiseAmp ("Noise Amplitude", Float) = 0.15
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // =====================================================
        // PASS 1 → LUZ DIRECCIONAL
        // =====================================================

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _AmbientLight;
            float4 _MaterialKa;

            float4 _F0;
            float _Roughness;

            float4 _ColorA;
            float4 _ColorB;

            float _RingScale;
            float _NoiseAmp;

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
                float3 localPos : TEXCOORD2;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w = UnityObjectToWorldNormal(v.normal);

                o.localPos = v.vertex.xyz;

                return o;
            }

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            float noise2D(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                float a = hash(i.x + i.y * 57.0);
                float b = hash(i.x + 1.0 + i.y * 57.0);
                float c = hash(i.x + (i.y + 1.0) * 57.0);
                float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);

                return lerp(
                    lerp(a, b, u.x),
                    lerp(c, d, u.x),
                    u.y
                );
            }

            float3 woodTexture(float3 localPos)
            {
                float radius =
                    sqrt(localPos.x * localPos.x +
                         localPos.z * localPos.z);

                float distortion =
                    noise2D(localPos.xz * 3.5) * _NoiseAmp;

                float ring =
                    frac((radius + distortion) * _RingScale);

                float smooth_ring =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smooth_ring
                );
            }

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha = roughness * roughness;
                float alpha2 = alpha * alpha;

                float denom =
                    NdotH * NdotH * (alpha2 - 1.0) + 1.0;

                return alpha2 /
                    (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotX, float roughness)
            {
                float k =
                    (roughness * roughness) / 2.0;

                return NdotX /
                    (NdotX * (1.0 - k) + k);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);

                // LUZ DIRECCIONAL
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.worldPos);

                float3 H =
                    normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float NdotV = max(0.0, dot(N, V));
                float NdotH = max(0.0, dot(N, H));
                float VdotH = max(0.0, dot(V, H));

                float3 albedo =
                    woodTexture(f.localPos);

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb *
                    albedo;

                float3 lightColor =
                    _LightColor0.rgb;

                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

                float D =
                    DistributionGGX(NdotH, _Roughness);

                float G =
                    GeometrySchlickGGX(NdotL, _Roughness) *
                    GeometrySchlickGGX(NdotV, _Roughness);

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                float3 diffuse =
                    albedo;

                float3 color =
                    ambient +
                    lightColor *
                    (diffuse + specular) *
                    NdotL;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // =====================================================
        // PASS 2 → POINT + SPOT
        // =====================================================

        Pass
        {
            Tags { "LightMode"="ForwardAdd" }

            Blend One One

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader
            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _F0;
            float _Roughness;

            float4 _ColorA;
            float4 _ColorB;

            float _RingScale;
            float _NoiseAmp;

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
                float3 localPos : TEXCOORD2;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position = UnityObjectToClipPos(v.vertex);

                o.worldPos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                o.localPos = v.vertex.xyz;

                return o;
            }

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            float noise2D(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float2 u = f * f * (3.0 - 2.0 * f);

                float a = hash(i.x + i.y * 57.0);
                float b = hash(i.x + 1.0 + i.y * 57.0);
                float c = hash(i.x + (i.y + 1.0) * 57.0);
                float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);

                return lerp(
                    lerp(a, b, u.x),
                    lerp(c, d, u.x),
                    u.y
                );
            }

            float3 woodTexture(float3 localPos)
            {
                float radius =
                    sqrt(localPos.x * localPos.x +
                         localPos.z * localPos.z);

                float distortion =
                    noise2D(localPos.xz * 3.5) * _NoiseAmp;

                float ring =
                    frac((radius + distortion) * _RingScale);

                float smooth_ring =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smooth_ring
                );
            }

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha = roughness * roughness;
                float alpha2 = alpha * alpha;

                float denom =
                    NdotH * NdotH * (alpha2 - 1.0) + 1.0;

                return alpha2 /
                    (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotX, float roughness)
            {
                float k =
                    (roughness * roughness) / 2.0;

                return NdotX /
                    (NdotX * (1.0 - k) + k);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);

                // POINT + SPOT
                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.worldPos *
                        _WorldSpaceLightPos0.w
                    );

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.worldPos);

                float3 H =
                    normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float NdotV = max(0.0, dot(N, V));
                float NdotH = max(0.0, dot(N, H));
                float VdotH = max(0.0, dot(V, H));

                float3 albedo =
                    woodTexture(f.localPos);

                float3 lightColor =
                    _LightColor0.rgb;

                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

                float D =
                    DistributionGGX(NdotH, _Roughness);

                float G =
                    GeometrySchlickGGX(NdotL, _Roughness) *
                    GeometrySchlickGGX(NdotV, _Roughness);

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                float3 diffuse =
                    albedo;

                float3 color =
                    lightColor *
                    (diffuse + specular) *
                    NdotL;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}