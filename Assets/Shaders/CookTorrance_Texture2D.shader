Shader "Custom/CookTorrance_Texture2D"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (1, 1, 1, 1)
        _MaterialKa      ("Material Ka",            Vector) = (0, 0, 0, 0)

        // Textura 2D: reemplaza al AlbedoColor
        _MainTex   ("Albedo Texture (2D)", 2D) = "white" {}

        _F0        ("F0 (Fresnel reflectance)", Vector) = (0.04, 0.04, 0.04, 0)
        _Roughness ("Roughness",               Float)  = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4    _LightIntensity;
            float4    _LightPosition_w;
            float4    _AmbientLight;
            float4    _MaterialKa;
            sampler2D _MainTex;
            float4    _MainTex_ST;   // necesario para TRANSFORM_TEX (tiling/offset)
            float4    _F0;
            float     _Roughness;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
                float2 uv         : TEXCOORD2;  // <-- coordenadas UV del mesh
            };

            v2f vertexShader(appdata_full v)   // appdata_full incluye UV
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w   = UnityObjectToWorldNormal(v.normal);
                // TRANSFORM_TEX aplica tiling y offset configurados en el inspector
                o.uv         = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha  = roughness * roughness;
                float alpha2 = alpha * alpha;
                float NdotH2 = NdotH * NdotH;
                float denom  = NdotH2 * (alpha2 - 1.0) + 1.0;
                return alpha2 / (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha = roughness * roughness;
                float k     = alpha / 2.0;
                return NdotV / (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(float NdotL, float NdotV, float roughness)
            {
                return GeometrySchlickGGX(NdotL, roughness)
                     * GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float NdotV = max(0.0, dot(N, V));
                float NdotH = max(0.0, dot(N, H));
                float VdotH = max(0.0, dot(V, H));

                // ---- Color del albedo viene de la textura 2D ----
                float3 albedo = tex2D(_MainTex, f.uv).rgb;

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse  = albedo;

                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GeometrySmith(NdotL, NdotV, _Roughness);

                float3 specular = (F * D * G) / (4.0 * NdotL * NdotV + 0.001);

                float3 color = ambient
                             + _LightIntensity.rgb * (diffuse + specular) * NdotL;

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}


/*
Shader "Custom/CookTorrance_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (1, 1, 1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0, 0, 0, 0)

        // Textura base
        _MainTex ("Albedo Texture (2D)", 2D) =
            "white" {}

        // Reflectancia Fresnel
        _F0 ("F0 (Fresnel Reflectance)", Vector) =
            (0.04, 0.04, 0.04, 0)

        // Rugosidad
        _Roughness ("Roughness", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → DIRECTIONAL LIGHT + AMBIENT
        // ============================================================

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                float2 uv : TEXCOORD2;
            };

            v2f vertexShader(appdata_full v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            // ========================================================
            // FRESNEL SCHLICK
            // ========================================================

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            // ========================================================
            // GGX DISTRIBUTION
            // ========================================================

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float alpha2 =
                    alpha * alpha;

                float NdotH2 =
                    NdotH * NdotH;

                float denom =
                    NdotH2 * (alpha2 - 1.0) + 1.0;

                return
                    alpha2 /
                    (UNITY_PI * denom * denom);
            }

            // ========================================================
            // GEOMETRY TERM
            // ========================================================

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith
            (
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                return
                    GeometrySchlickGGX(NdotL, roughness) *
                    GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                // Luz direccional
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                float3 H =
                    normalize(L + V);

                // ====================================================
                // DOT PRODUCTS
                // ====================================================

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                // ====================================================
                // ALBEDO
                // ====================================================

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // AMBIENT
                // ====================================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // ====================================================
                // DIFFUSE
                // ====================================================

                float3 diffuse =
                    albedo;

                // ====================================================
                // COOK-TORRANCE SPECULAR
                // ====================================================

                float3 F =
                    FresnelSchlick(
                        _F0.rgb,
                        VdotH
                    );

                float D =
                    DistributionGGX(
                        NdotH,
                        _Roughness
                    );

                float G =
                    GeometrySmith(
                        NdotL,
                        NdotV,
                        _Roughness
                    );

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    ambient +
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    NdotL;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // ============================================================
        // PASS 2 → POINT LIGHTS + SPOT LIGHTS
        // ============================================================

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                float2 uv : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vertexShader(appdata_full v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            // ========================================================
            // FRESNEL SCHLICK
            // ========================================================

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            // ========================================================
            // GGX DISTRIBUTION
            // ========================================================

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float alpha2 =
                    alpha * alpha;

                float NdotH2 =
                    NdotH * NdotH;

                float denom =
                    NdotH2 * (alpha2 - 1.0) + 1.0;

                return
                    alpha2 /
                    (UNITY_PI * denom * denom);
            }

            // ========================================================
            // GEOMETRY TERM
            // ========================================================

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith
            (
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                return
                    GeometrySchlickGGX(NdotL, roughness) *
                    GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                // Point / Spot
                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.position_w
                    );

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                float3 H =
                    normalize(L + V);

                // Atenuación automática
                LIGHT_ATTENUATION(atten, f);

                // ====================================================
                // DOT PRODUCTS
                // ====================================================

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                // ====================================================
                // ALBEDO
                // ====================================================

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // DIFFUSE
                // ====================================================

                float3 diffuse =
                    albedo;

                // ====================================================
                // COOK-TORRANCE SPECULAR
                // ====================================================

                float3 F =
                    FresnelSchlick(
                        _F0.rgb,
                        VdotH
                    );

                float D =
                    DistributionGGX(
                        NdotH,
                        _Roughness
                    );

                float G =
                    GeometrySmith(
                        NdotL,
                        NdotV,
                        _Roughness
                    );

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    NdotL *
                    atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}*/


/*
Shader "Custom/CookTorrance_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (1, 1, 1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0, 0, 0, 0)

        _MainTex ("Albedo Texture (2D)", 2D) =
            "white" {}

        _F0 ("F0 (Fresnel Reflectance)", Vector) =
            (0.04, 0.04, 0.04, 0)

        _Roughness ("Roughness", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → DIRECTIONAL LIGHT + AMBIENT
        // ============================================================

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _F0;
            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 position_w : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vertexShader(appdata_full v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float alpha2 =
                    alpha * alpha;

                float NdotH2 =
                    NdotH * NdotH;

                float denom =
                    NdotH2 * (alpha2 - 1.0) + 1.0;

                return
                    alpha2 /
                    (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith
            (
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                return
                    GeometrySchlickGGX(NdotL, roughness) *
                    GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                // DIRECCIONAL
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                float3 H =
                    normalize(L + V);

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                float3 diffuse =
                    albedo;

                float3 F =
                    FresnelSchlick(
                        _F0.rgb,
                        VdotH
                    );

                float D =
                    DistributionGGX(
                        NdotH,
                        _Roughness
                    );

                float G =
                    GeometrySmith(
                        NdotL,
                        NdotV,
                        _Roughness
                    );

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                float3 color =
                    ambient +
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    NdotL;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // ============================================================
        // PASS 2 → POINT LIGHTS + SPOT LIGHTS
        // ============================================================

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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _F0;
            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                float2 uv : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vertexShader(appdata_full v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float alpha2 =
                    alpha * alpha;

                float NdotH2 =
                    NdotH * NdotH;

                float denom =
                    NdotH2 * (alpha2 - 1.0) + 1.0;

                return
                    alpha2 /
                    (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith
            (
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                return
                    GeometrySchlickGGX(NdotL, roughness) *
                    GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                // POINT / SPOT
                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.position_w *
                        _WorldSpaceLightPos0.w
                    );

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                float3 H =
                    normalize(L + V);

                LIGHT_ATTENUATION(atten, f);

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                float3 diffuse =
                    albedo;

                float3 F =
                    FresnelSchlick(
                        _F0.rgb,
                        VdotH
                    );

                float D =
                    DistributionGGX(
                        NdotH,
                        _Roughness
                    );

                float G =
                    GeometrySmith(
                        NdotL,
                        NdotV,
                        _Roughness
                    );

                float3 specular =
                    (F * D * G) /
                    (4.0 * NdotL * NdotV + 0.001);

                float3 color =
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    NdotL *
                    atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}*/