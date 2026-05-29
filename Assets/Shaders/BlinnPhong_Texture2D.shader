Shader "Custom/BlinnPhong_Texture2D"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (1, 1, 1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)
        _MaterialKs ("Material Ks", Vector) = (0.5, 0.5, 0.5, 0)
        _Material_n ("Material n (shininess)", Float) = 64

        // La textura reemplaza a Kd
        _MainTex ("Albedo Texture (2D)", 2D) = "white" {}
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
            float4    _MaterialKs;
            float     _Material_n;
            sampler2D _MainTex;
            float4    _MainTex_ST;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
            };

            v2f vertexShader(appdata_full v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w   = UnityObjectToWorldNormal(v.normal);
                o.uv         = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                // Kd viene de la textura
                float3 Kd = tex2D(_MainTex, f.uv).rgb;

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse  = _LightIntensity.rgb * Kd * max(0.0, dot(N, L));
                float3 specular = _LightIntensity.rgb * _MaterialKs.rgb
                                * pow(max(0.0, dot(N, H)), _Material_n)
                                * max(0.0, dot(N, L));

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}


/*

Shader "Custom/BlinnPhong_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light",  Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa   ("Material Ka",   Vector)  = (0.1, 0.1, 0.1, 0)
        _MaterialKs   ("Material Ks",   Vector)  = (0.5, 0.5, 0.5, 0)
        _Material_n   ("Material n (shininess)", Float) = 64
        _MainTex      ("Albedo Texture (2D)", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ── PASS 1: luz direccional (ForwardBase) ──────────────────────────
        Pass
        {
            Tags { "LightMode"="ForwardBase" }
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            float4    _AmbientLight;
            float4    _MaterialKa;
            float4    _MaterialKs;
            float     _Material_n;
            sampler2D _MainTex;
            float4    _MainTex_ST;

            struct v2f {
                float4 pos    : SV_POSITION;
                float3 wpos   : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv     : TEXCOORD2;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos    = UnityObjectToClipPos(v.vertex);
                o.wpos   = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv     = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz); // direccional: w==0
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);
                float3 H = normalize(L + V);

                float3 Kd = tex2D(_MainTex, f.uv).rgb;
                float3 lightColor = _LightColor0.rgb;

                float NdotL = max(0.0, dot(N, L));
                float NdotH = max(0.0, dot(N, H));

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb * Kd;
                float3 diffuse  = lightColor * Kd * NdotL;
                float3 specular = lightColor * _MaterialKs.rgb
                                * pow(NdotH, _Material_n) * NdotL;

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }

        // ── PASS 2: luces adicionales (Point + Spot) ───────────────────────
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            float4    _MaterialKs;
            float     _Material_n;
            sampler2D _MainTex;
            float4    _MainTex_ST;

            struct v2f {
                float4 pos    : SV_POSITION;
                float3 wpos   : TEXCOORD0;
                float3 normal : TEXCOORD1;
                float2 uv     : TEXCOORD2;
            };

            v2f vert(appdata_full v)
            {
                v2f o;
                o.pos    = UnityObjectToClipPos(v.vertex);
                o.wpos   = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.uv     = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                // Point/Spot: _WorldSpaceLightPos0.w == 1, restar posicion
                float3 L = normalize(_WorldSpaceLightPos0.xyz - f.wpos * _WorldSpaceLightPos0.w);
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);
                float3 H = normalize(L + V);

                float3 Kd = tex2D(_MainTex, f.uv).rgb;
                float3 lightColor = _LightColor0.rgb;

                float NdotL = max(0.0, dot(N, L));
                float NdotH = max(0.0, dot(N, H));

                float3 diffuse  = lightColor * Kd * NdotL;
                float3 specular = lightColor * _MaterialKs.rgb
                                * pow(NdotH, _Material_n) * NdotL;

                return fixed4(diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
}
*/


/*
Shader "Custom/BlinnPhong_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)

        _MaterialKs ("Material Ks", Vector) = (0.5, 0.5, 0.5, 0)

        _Material_n ("Material n (shininess)", Float) = 64

        _MainTex ("Albedo Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → LUZ PRINCIPAL (Directional + Ambient)
        // ============================================================

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _AmbientLight;

            float4 _MaterialKa;

            float4 _MaterialKs;

            float _Material_n;

            sampler2D _MainTex;

            float4 _MainTex_ST;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal);

                // Luz direccional
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.wpos);

                float3 H =
                    normalize(L + V);

                float3 Kd =
                    tex2D(_MainTex, f.uv).rgb;

                float3 lightColor =
                    _LightColor0.rgb;

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotH =
                    max(0.0, dot(N, H));

                // Ambient
                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb *
                    Kd;

                // Diffuse
                float3 diffuse =
                    lightColor *
                    Kd *
                    NdotL;

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL;

                return fixed4(
                    ambient + diffuse + specular,
                    1.0
                );
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

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            float4 _MaterialKs;

            float _Material_n;

            sampler2D _MainTex;

            float4 _MainTex_ST;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float2 uv : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal);

                // Luz Point / Spot
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz - f.wpos);

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.wpos);

                float3 H =
                    normalize(L + V);

                // Attenuation automática
              
               LIGHT_ATTENUATION(f);

                float3 Kd =
                    tex2D(_MainTex, f.uv).rgb;

                float3 lightColor =
                    _LightColor0.rgb;

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotH =
                    max(0.0, dot(N, H));

                // Diffuse
                float3 diffuse =
                    lightColor *
                    Kd *
                    NdotL *
                    atten;

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL *
                    atten;

                return fixed4(
                    diffuse + specular,
                    1.0
                );
            }

            ENDCG
        }
    }
}
*/


/*
Shader "Custom/BlinnPhong_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)

        _MaterialKs ("Material Ks", Vector) = (0.5, 0.5, 0.5, 0)

        _Material_n ("Material n (shininess)", Float) = 64

        _MainTex ("Albedo Texture", 2D) = "white" {}
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → LUZ PRINCIPAL (Directional + Ambient)
        // ============================================================

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _AmbientLight;

            float4 _MaterialKa;

            float4 _MaterialKs;

            float _Material_n;

            sampler2D _MainTex;

            float4 _MainTex_ST;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float2 uv : TEXCOORD2;
            };

            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos = UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal);

                // Luz direccional
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.wpos);

                float3 H =
                    normalize(L + V);

                float3 Kd =
                    tex2D(_MainTex, f.uv).rgb;

                float3 lightColor =
                    _LightColor0.rgb;

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotH =
                    max(0.0, dot(N, H));

                // Ambient
                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb *
                    Kd;

                // Diffuse
                float3 diffuse =
                    lightColor *
                    Kd *
                    NdotL;

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL;

                return fixed4(
                    ambient + diffuse + specular,
                    1.0
                );
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

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _MaterialKs;

            float _Material_n;

            sampler2D _MainTex;

            float4 _MainTex_ST;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float2 uv : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vert(appdata_full v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal);

                // Luz Point / Spot
                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.wpos
                    );

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos - f.wpos
                    );

                float3 H =
                    normalize(L + V);

                // Attenuation automática
                LIGHT_ATTENUATION(atten, f);

                float3 Kd =
                    tex2D(_MainTex, f.uv).rgb;

                float3 lightColor =
                    _LightColor0.rgb;

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotH =
                    max(0.0, dot(N, H));

                // Diffuse
                float3 diffuse =
                    lightColor *
                    Kd *
                    NdotL *
                    atten;

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL *
                    atten;

                return fixed4(
                    diffuse + specular,
                    1.0
                );
            }

            ENDCG
        }
    }
}*/