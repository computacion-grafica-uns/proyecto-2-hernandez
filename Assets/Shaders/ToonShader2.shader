
Shader "Custom/ToonShader2"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (0.1, 0.1, 0.1, 1)

        _MaterialKa  ("Material Ka",  Vector) = (0.1, 0.1, 0.1, 0)
        _BaseColor   ("Base Color",   Color)  = (0.8, 0.3, 0.1, 1)
        _ShadowColor ("Shadow Color", Color)  = (0.3, 0.1, 0.05, 1)

        // Cuantas bandas de color (2, 3 o 4)
        _Bands       ("Toon Bands",   Float)  = 3.0

        // Especular toon (umbral y suavizado)
        _SpecColor2  ("Specular Color",     Color) = (1, 1, 1, 1)
        _SpecThresh  ("Specular Threshold", Float) = 0.85
        _SpecSmooth  ("Specular Smoothness",Float) = 0.02

        // Contorno
        _OutlineColor ("Outline Color",     Color) = (0, 0, 0, 1)
        _OutlineWidth ("Outline Width",     Float) = 0.02
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        // =============================================
        // PASS 1: Iluminacion Toon (difusa + especular)
        // =============================================
        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _BaseColor;
            float4 _ShadowColor;
            float  _Bands;
            float4 _SpecColor2;
            float  _SpecThresh;
            float  _SpecSmooth;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w   = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                // -----------------------------------
                // Difuso cuantizado (bandas Toon)
                // -----------------------------------
                // NdotL continuo [0,1]
                float NdotL = max(0.0, dot(N, L));

                // Cuantizamos: floor(NdotL * _Bands) / _Bands
                // Esto genera escalones de color bien definidos
                float toonDiff = floor(NdotL * _Bands) / _Bands;

                // Interpolamos entre ShadowColor y BaseColor segun toonDiff
                float3 diffuse = lerp(_ShadowColor.rgb, _BaseColor.rgb, toonDiff);

                // -----------------------------------
                // Especular toon: "mancha" dura
                // smoothstep genera un borde suave pero muy estrecho
                // -----------------------------------
                float NdotH    = max(0.0, dot(N, H));
                float specMask = smoothstep(_SpecThresh - _SpecSmooth,
                                            _SpecThresh + _SpecSmooth,
                                            NdotH);
                float3 specular = _SpecColor2.rgb * specMask;

                // -----------------------------------
                // Ambiente
                // -----------------------------------
                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // -----------------------------------
                // Color final
                // -----------------------------------
                float3 color = ambient
                             + _LightIntensity.rgb * (diffuse + specular);

                return fixed4(color, 1.0);
            }
            ENDCG
        }

        // =============================================
        // PASS 2: Contorno (Outline) - truco de inversion de normales
        // Se renderiza el mesh expandido hacia afuera con las caras invertidas
        // Solo se ven las caras traseras => genera silueta negra
        // =============================================
        Pass
        {
            Cull Front   // Culleamos las caras frontales, mostramos las traseras

            CGPROGRAM
            #pragma vertex   outlineVert
            #pragma fragment outlineFrag
            #include "UnityCG.cginc"

            float4 _OutlineColor;
            float  _OutlineWidth;

            struct v2f_outline
            {
                float4 position : SV_POSITION;
            };

            v2f_outline outlineVert(appdata_base v)
            {
                v2f_outline o;

                // Expandimos el vertice a lo largo de su normal en espacio objeto
                float3 expandedPos = v.vertex.xyz + v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(float4(expandedPos, 1.0));
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


/*
Shader "Custom/ToonShader2"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        // Colores toon
        _BaseColor ("Base Color", Color) =
            (0.8, 0.3, 0.1, 1)

        _ShadowColor ("Shadow Color", Color) =
            (0.3, 0.1, 0.05, 1)

        // Bandas toon
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

            float4 _BaseColor;

            float4 _ShadowColor;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                return o;
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
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0, dot(N, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 diffuse =
                    lerp(
                        _ShadowColor.rgb,
                        _BaseColor.rgb,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0, dot(N, H));

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

            float4 _BaseColor;

            float4 _ShadowColor;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                LIGHTING_COORDS(2,3)
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
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
                // TOON DIFFUSE
                // ====================================================

                float NdotL =
                    max(0.0, dot(N, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 diffuse =
                    lerp(
                        _ShadowColor.rgb,
                        _BaseColor.rgb,
                        toonDiff
                    );

                // ====================================================
                // TOON SPECULAR
                // ====================================================

                float NdotH =
                    max(0.0, dot(N, H));

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
Shader "Custom/ToonShader2"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        // ======================================
        // DIRECTIONAL LIGHT
        // ======================================

        _DirLightColor ("Directional Light Color", Color) =
            (1,1,1,1)

        _DirLightDirection ("Directional Light Direction", Vector) =
            (0,-1,0,0)

        // ======================================
        // POINT LIGHT
        // ======================================

        _PointLightColor ("Point Light Color", Color) =
            (1,1,1,1)

        _PointLightPosition ("Point Light Position", Vector) =
            (0,5,0,1)

        // ======================================
        // SPOT LIGHT
        // ======================================

        _SpotLightColor ("Spot Light Color", Color) =
            (1,1,1,1)

        _SpotLightPosition ("Spot Light Position", Vector) =
            (0,5,0,1)

        _SpotLightDirection ("Spot Light Direction", Vector) =
            (0,-1,0,0)

        _SpotAngle ("Spot Angle", Float) = 0.9

        // ======================================
        // MATERIAL
        // ======================================

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        // Colores toon
        _BaseColor ("Base Color", Color) =
            (0.8, 0.3, 0.1, 1)

        _ShadowColor ("Shadow Color", Color) =
            (0.3, 0.1, 0.05, 1)

        // Bandas toon
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
        // MAIN PASS
        // ============================================================

        Pass
        {
            Cull Back

            CGPROGRAM

            #pragma vertex vertexShader
            #pragma fragment fragmentShader

            #include "UnityCG.cginc"

            float4 _AmbientLight;

            float4 _DirLightColor;
            float4 _DirLightDirection;

            float4 _PointLightColor;
            float4 _PointLightPosition;

            float4 _SpotLightColor;
            float4 _SpotLightPosition;
            float4 _SpotLightDirection;
            float _SpotAngle;

            float4 _MaterialKa;

            float4 _BaseColor;

            float4 _ShadowColor;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                return o;
            }

            // ==========================================
            // TOON LIGHT FUNCTION
            // ==========================================

            float3 ComputeToonLight(
                float3 lightColor,
                float3 L,
                float3 N,
                float3 V
            )
            {
                float3 H =
                    normalize(L + V);

                // =========================
                // TOON DIFFUSE
                // =========================

                float NdotL =
                    max(0.0, dot(N, L));

                float toonDiff =
                    floor(NdotL * _Bands) / _Bands;

                float3 diffuse =
                    lerp(
                        _ShadowColor.rgb,
                        _BaseColor.rgb,
                        toonDiff
                    );

                // =========================
                // TOON SPECULAR
                // =========================

                float NdotH =
                    max(0.0, dot(N, H));

                float specMask =
                    smoothstep(
                        _SpecThresh - _SpecSmooth,
                        _SpecThresh + _SpecSmooth,
                        NdotH
                    );

                float3 specular =
                    _SpecColor2.rgb * specMask;

                return
                    lightColor *
                    (diffuse + specular);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                // ======================================
                // AMBIENT
                // ======================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // ======================================
                // DIRECTIONAL LIGHT
                // ======================================

                float3 Ld =
                    normalize(
                        -_DirLightDirection.xyz
                    );

                float3 directional =
                    ComputeToonLight(
                        _DirLightColor.rgb,
                        Ld,
                        N,
                        V
                    );

                // ======================================
                // POINT LIGHT
                // ======================================

                float3 Lp =
                    normalize(
                        _PointLightPosition.xyz -
                        f.position_w
                    );

                float3 point1 =
                    ComputeToonLight(
                        _PointLightColor.rgb,
                        Lp,
                        N,
                        V
                    );

                // ======================================
                // SPOT LIGHT
                // ======================================

                float3 Ls =
                    normalize(
                        _SpotLightPosition.xyz -
                        f.position_w
                    );

                float spotFactor =
                    dot(
                        normalize(-_SpotLightDirection.xyz),
                        Ls
                    );

                spotFactor =
                    step(_SpotAngle, spotFactor);

                float3 spot =
                    ComputeToonLight(
                        _SpotLightColor.rgb * spotFactor,
                        Ls,
                        N,
                        V
                    );

                // ======================================
                // FINAL COLOR
                // ======================================

                float3 color =
                    ambient +
                    directional +
                    point1 +
                    spot;

                return fixed4(color, 1.0);
            }

            ENDCG
        }

        // ============================================================
        // OUTLINE PASS
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