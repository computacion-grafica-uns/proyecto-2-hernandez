Shader "Custom/ToonShader_NormalMap"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa      ("Material Ka",            Vector) = (0.1, 0.1, 0.1, 0)

        _MainTex     ("Albedo Texture",      2D)    = "white" {}
        _NormalMap   ("Normal Map",          2D)    = "bump"  {}
        _NormalScale ("Normal Scale",        Float) = 1.0
        _ShadowMult  ("Shadow Multiplier",   Float) = 0.35

        _Bands       ("Toon Bands",          Float) = 3.0
        _SpecColor2  ("Specular Color",      Color) = (1, 1, 1, 1)
        _SpecThresh  ("Specular Threshold",  Float) = 0.85
        _SpecSmooth  ("Specular Smoothness", Float) = 0.02

        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width", Float) = 0.02
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            Cull Back
            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4    _LightIntensity;
            float4    _LightPosition_w;
            float4    _AmbientLight;
            float4    _MaterialKa;
            sampler2D _MainTex;
            float4    _MainTex_ST;
            sampler2D _NormalMap;
            float4    _NormalMap_ST;
            float     _NormalScale;
            float     _ShadowMult;
            float     _Bands;
            float4    _SpecColor2;
            float     _SpecThresh;
            float     _SpecSmooth;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float2 uv         : TEXCOORD1;
                float3 T_w        : TEXCOORD2;
                float3 B_w        : TEXCOORD3;
                float3 N_w        : TEXCOORD4;
            };

            v2f vertexShader(appdata_tan v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.uv         = TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 N = UnityObjectToWorldNormal(v.normal);
                float3 T = UnityObjectToWorldDir(v.tangent.xyz);
                float3 B = cross(N, T) * v.tangent.w;

                o.T_w = T;
                o.B_w = B;
                o.N_w = N;
                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // Normal mapping: desempaquetar y transformar a espacio mundo
                float3 normalTS = UnpackNormal(tex2D(_NormalMap, f.uv));
                normalTS.xy *= _NormalScale;
                normalTS = normalize(normalTS);

                float3 T = normalize(f.T_w);
                float3 B = normalize(f.B_w);
                float3 N = normalize(f.N_w);
                float3 worldNormal = normalize(T * normalTS.x + B * normalTS.y + N * normalTS.z);

                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float3 texColor = tex2D(_MainTex, f.uv).rgb;

                // Difuso cuantizado usando la normal mapeada
                float NdotL    = max(0.0, dot(worldNormal, L));
                float toonDiff = floor(NdotL * _Bands) / _Bands;

                float3 shadowColor = texColor * _ShadowMult;
                float3 diffuse     = lerp(shadowColor, texColor, toonDiff);

                // Especular toon usando la normal mapeada
                float NdotH    = max(0.0, dot(worldNormal, H));
                float specMask = smoothstep(_SpecThresh - _SpecSmooth,
                                            _SpecThresh + _SpecSmooth, NdotH);
                float3 specular = _SpecColor2.rgb * specMask;

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 color   = ambient + _LightIntensity.rgb * (diffuse + specular);

                return fixed4(color, 1.0);
            }
            ENDCG
        }

        Pass
        {
            Cull Front
            CGPROGRAM
            #pragma vertex   outlineVert
            #pragma fragment outlineFrag
            #include "UnityCG.cginc"

            float4 _OutlineColor;
            float  _OutlineWidth;

            struct v2f_outline { float4 position : SV_POSITION; };

            v2f_outline outlineVert(appdata_base v)
            {
                v2f_outline o;
                float3 expandedPos = v.vertex.xyz + v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(float4(expandedPos, 1.0));
                return o;
            }

            fixed4 outlineFrag(v2f_outline f) : SV_Target { return _OutlineColor; }
            ENDCG
        }
    }
}


/*
Shader "Custom/ToonShader_NormalMap"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        // Texturas
        _MainTex ("Albedo Texture", 2D) =
            "white" {}

        _NormalMap ("Normal Map", 2D) =
            "bump" {}

        _NormalScale ("Normal Scale", Float) = 1.0

        // Toon
        _ShadowMult ("Shadow Multiplier", Float) = 0.35

        _Bands ("Toon Bands", Float) = 3.0

        // Specular toon
        _SpecColor2 ("Specular Color", Color) =
            (1, 1, 1, 1)

        _SpecThresh ("Specular Threshold", Float) = 0.85

        _SpecSmooth ("Specular Smoothness", Float) = 0.02

        // Outline
        _OutlineColor ("Outline Color", Color) =
            (0, 0, 0, 1)

        _OutlineWidth ("Outline Width", Float) = 0.02
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

            Cull Back

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

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float _ShadowMult;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float2 uv : TEXCOORD1;

                float3 T_w : TEXCOORD2;

                float3 B_w : TEXCOORD3;

                float3 N_w : TEXCOORD4;
            };

            v2f vertexShader(appdata_tan v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 N =
                    UnityObjectToWorldNormal(v.normal);

                float3 T =
                    UnityObjectToWorldDir(v.tangent.xyz);

                float3 B =
                    cross(N, T) * v.tangent.w;

                o.T_w = T;

                o.B_w = B;

                o.N_w = N;

                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // ====================================================
                // NORMAL MAP
                // ====================================================

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;

                normalTS =
                    normalize(normalTS);

                float3 T =
                    normalize(f.T_w);

                float3 B =
                    normalize(f.B_w);

                float3 N =
                    normalize(f.N_w);

                float3 worldNormal =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ====================================================
                // LUCES
                // ====================================================

                // Direccional
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
                // COLOR BASE
                // ====================================================

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0,
                        dot(worldNormal, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 shadowColor =
                    texColor * _ShadowMult;

                float3 diffuse =
                    lerp(
                        shadowColor,
                        texColor,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0,
                        dot(worldNormal, H));

                float specMask =
                    smoothstep(
                        _SpecThresh - _SpecSmooth,
                        _SpecThresh + _SpecSmooth,
                        NdotH
                    );

                float3 specular =
                    _SpecColor2.rgb * specMask;

                // ====================================================
                // AMBIENT
                // ====================================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    ambient +
                    _LightColor0.rgb *
                    (diffuse + specular);

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

            Cull Back

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader

            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float _ShadowMult;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float2 uv : TEXCOORD1;

                float3 T_w : TEXCOORD2;

                float3 B_w : TEXCOORD3;

                float3 N_w : TEXCOORD4;

                LIGHTING_COORDS(5,6)
            };

            v2f vertexShader(appdata_tan v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 N =
                    UnityObjectToWorldNormal(v.normal);

                float3 T =
                    UnityObjectToWorldDir(v.tangent.xyz);

                float3 B =
                    cross(N, T) * v.tangent.w;

                o.T_w = T;

                o.B_w = B;

                o.N_w = N;

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // ====================================================
                // NORMAL MAP
                // ====================================================

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;

                normalTS =
                    normalize(normalTS);

                float3 T =
                    normalize(f.T_w);

                float3 B =
                    normalize(f.B_w);

                float3 N =
                    normalize(f.N_w);

                float3 worldNormal =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ====================================================
                // POINT / SPOT
                // ====================================================

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
                // TEXTURA
                // ====================================================

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0,
                        dot(worldNormal, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 shadowColor =
                    texColor * _ShadowMult;

                float3 diffuse =
                    lerp(
                        shadowColor,
                        texColor,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0,
                        dot(worldNormal, H));

                float specMask =
                    smoothstep(
                        _SpecThresh - _SpecSmooth,
                        _SpecThresh + _SpecSmooth,
                        NdotH
                    );

                float3 specular =
                    _SpecColor2.rgb * specMask;

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // ============================================================
        // PASS 3 → OUTLINE
        // ============================================================

        Pass
        {
            Cull Front

            CGPROGRAM

            #pragma vertex outlineVert
            #pragma fragment outlineFrag

            #include "UnityCG.cginc"

            float4 _OutlineColor;

            float _OutlineWidth;

            struct v2f_outline
            {
                float4 position : SV_POSITION;
            };

            v2f_outline outlineVert(appdata_base v)
            {
                v2f_outline o;

                float3 expandedPos =
                    v.vertex.xyz +
                    v.normal * _OutlineWidth;

                o.position =
                    UnityObjectToClipPos(
                        float4(expandedPos, 1.0)
                    );

                return o;
            }

            fixed4 outlineFrag(v2f_outline f) : SV_Target
            {
                return _OutlineColor;
            }

            ENDCG
        }
    }
}
    */

/*

Shader "Custom/ToonShader_NormalMap"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        // Texturas
        _MainTex ("Albedo Texture", 2D) =
            "white" {}

        _NormalMap ("Normal Map", 2D) =
            "bump" {}

        _NormalScale ("Normal Scale", Float) = 1.0

        // Toon
        _ShadowMult ("Shadow Multiplier", Float) = 0.35

        _Bands ("Toon Bands", Float) = 3.0

        // Specular toon
        _SpecColor2 ("Specular Color", Color) =
            (1, 1, 1, 1)

        _SpecThresh ("Specular Threshold", Float) = 0.85

        _SpecSmooth ("Specular Smoothness", Float) = 0.02

        // Outline
        _OutlineColor ("Outline Color", Color) =
            (0, 0, 0, 1)

        _OutlineWidth ("Outline Width", Float) = 0.02
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

            Cull Back

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

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float _ShadowMult;
            float _Bands;

            float4 _SpecColor2;
            float _SpecThresh;
            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 position_w : TEXCOORD0;
                float2 uv : TEXCOORD1;

                float3 T_w : TEXCOORD2;
                float3 B_w : TEXCOORD3;
                float3 N_w : TEXCOORD4;
            };

            v2f vertexShader(appdata_tan v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 N =
                    UnityObjectToWorldNormal(v.normal);

                float3 T =
                    UnityObjectToWorldDir(v.tangent.xyz);

                float3 B =
                    cross(N, T) * v.tangent.w;

                o.T_w = T;
                o.B_w = B;
                o.N_w = N;

                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // ====================================================
                // NORMAL MAP
                // ====================================================

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;
                normalTS = normalize(normalTS);

                float3 T = normalize(f.T_w);
                float3 B = normalize(f.B_w);
                float3 N = normalize(f.N_w);

                float3 worldNormal =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ====================================================
                // LUZ DIRECCIONAL
                // ====================================================

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
                // TEXTURA
                // ====================================================

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0,
                        dot(worldNormal, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 shadowColor =
                    texColor * _ShadowMult;

                float3 diffuse =
                    lerp(
                        shadowColor,
                        texColor,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0,
                        dot(worldNormal, H));

                float specMask =
                    smoothstep(
                        _SpecThresh - _SpecSmooth,
                        _SpecThresh + _SpecSmooth,
                        NdotH
                    );

                float3 specular =
                    _SpecColor2.rgb * specMask;

                // ====================================================
                // AMBIENT
                // ====================================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    ambient +
                    _LightColor0.rgb *
                    (diffuse + specular);

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

            Cull Back

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader

            #pragma multi_compile_fwdadd

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float _ShadowMult;
            float _Bands;

            float4 _SpecColor2;
            float _SpecThresh;
            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float2 uv : TEXCOORD1;

                float3 T_w : TEXCOORD2;

                float3 B_w : TEXCOORD3;

                float3 N_w : TEXCOORD4;

                LIGHTING_COORDS(5,6)
            };

            v2f vertexShader(appdata_tan v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv =
                    TRANSFORM_TEX(v.texcoord, _MainTex);

                float3 N =
                    UnityObjectToWorldNormal(v.normal);

                float3 T =
                    UnityObjectToWorldDir(v.tangent.xyz);

                float3 B =
                    cross(N, T) * v.tangent.w;

                o.T_w = T;
                o.B_w = B;
                o.N_w = N;

                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // ====================================================
                // NORMAL MAP
                // ====================================================

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;
                normalTS = normalize(normalTS);

                float3 T = normalize(f.T_w);
                float3 B = normalize(f.B_w);
                float3 N = normalize(f.N_w);

                float3 worldNormal =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ====================================================
                // POINT / SPOT
                // ====================================================

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

                // ====================================================
                // TEXTURA
                // ====================================================

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                // ====================================================
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0,
                        dot(worldNormal, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 shadowColor =
                    texColor * _ShadowMult;

                float3 diffuse =
                    lerp(
                        shadowColor,
                        texColor,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0,
                        dot(worldNormal, H));

                float specMask =
                    smoothstep(
                        _SpecThresh - _SpecSmooth,
                        _SpecThresh + _SpecSmooth,
                        NdotH
                    );

                float3 specular =
                    _SpecColor2.rgb * specMask;

                // ====================================================
                // FINAL
                // ====================================================

                float3 color =
                    _LightColor0.rgb *
                    (diffuse + specular) *
                    atten;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // ============================================================
        // PASS 3 → OUTLINE
        // ============================================================

        Pass
        {
            Cull Front

            CGPROGRAM

            #pragma vertex outlineVert
            #pragma fragment outlineFrag

            #include "UnityCG.cginc"

            float4 _OutlineColor;
            float _OutlineWidth;

            struct v2f_outline
            {
                float4 position : SV_POSITION;
            };

            v2f_outline outlineVert(appdata_base v)
            {
                v2f_outline o;

                float3 expandedPos =
                    v.vertex.xyz +
                    v.normal * _OutlineWidth;

                o.position =
                    UnityObjectToClipPos(
                        float4(expandedPos, 1.0)
                    );

                return o;
            }

            fixed4 outlineFrag(v2f_outline f) : SV_Target
            {
                return _OutlineColor;
            }

            ENDCG
        }
    }
}*/