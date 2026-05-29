/*Shader "Custom/ToonShader_Procedural"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa      ("Material Ka",            Vector) = (0.1, 0.1, 0.1, 0)

        _ColorA    ("Color A (anillo claro)", Color) = (0.85, 0.55, 0.25, 1)
        _ColorB    ("Color B (anillo oscuro)",Color) = (0.45, 0.22, 0.08, 1)
        _RingScale ("Ring Scale",            Float) = 8.0
        _NoiseAmp  ("Noise Amplitude",       Float) = 0.15
        _ShadowMult("Shadow Multiplier",     Float) = 0.35

        _Bands      ("Toon Bands",           Float) = 3.0
        _SpecColor2 ("Specular Color",       Color) = (1, 1, 1, 1)
        _SpecThresh ("Specular Threshold",   Float) = 0.85
        _SpecSmooth ("Specular Smoothness",  Float) = 0.02

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

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _ColorA;
            float4 _ColorB;
            float  _RingScale;
            float  _NoiseAmp;
            float  _ShadowMult;
            float  _Bands;
            float4 _SpecColor2;
            float  _SpecThresh;
            float  _SpecSmooth;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
                float3 localPos   : TEXCOORD2;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w   = UnityObjectToWorldNormal(v.normal);
                o.localPos   = v.vertex.xyz;
                return o;
            }

            float hash(float n) { return frac(sin(n) * 43758.5453123); }

            float noise2D(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = hash(i.x       + i.y * 57.0);
                float b = hash(i.x + 1.0 + i.y * 57.0);
                float c = hash(i.x       + (i.y + 1.0) * 57.0);
                float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            float3 woodTexture(float3 localPos)
            {
                float radius      = sqrt(localPos.x * localPos.x + localPos.z * localPos.z);
                float distortion  = noise2D(localPos.xz * 3.5) * _NoiseAmp;
                float ring        = frac((radius + distortion) * _RingScale);
                float smooth_ring = smoothstep(0.45, 0.55, ring);
                return lerp(_ColorA.rgb, _ColorB.rgb, smooth_ring);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float3 texColor = woodTexture(f.localPos);

                float NdotL    = max(0.0, dot(N, L));
                float toonDiff = floor(NdotL * _Bands) / _Bands;

                float3 shadowColor = texColor * _ShadowMult;
                float3 diffuse     = lerp(shadowColor, texColor, toonDiff);

                float NdotH    = max(0.0, dot(N, H));
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
}*/

/*
Shader "Custom/ToonShader_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        // Colores madera procedural
        _ColorA ("Color A (anillo claro)", Color) =
            (0.85, 0.55, 0.25, 1)

        _ColorB ("Color B (anillo oscuro)", Color) =
            (0.45, 0.22, 0.08, 1)

        _RingScale ("Ring Scale", Float) = 8.0

        _NoiseAmp ("Noise Amplitude", Float) = 0.15

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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            float _ShadowMult;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                float3 localPos : TEXCOORD2;
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

                o.localPos =
                    v.vertex.xyz;

                return o;
            }

            // ========================================================
            // NOISE
            // ========================================================

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            float noise2D(float2 p)
            {
                float2 i = floor(p);

                float2 f = frac(p);

                float2 u =
                    f * f * (3.0 - 2.0 * f);

                float a =
                    hash(i.x + i.y * 57.0);

                float b =
                    hash(i.x + 1.0 + i.y * 57.0);

                float c =
                    hash(i.x + (i.y + 1.0) * 57.0);

                float d =
                    hash(i.x + 1.0 + (i.y + 1.0) * 57.0);

                return lerp(
                    lerp(a, b, u.x),
                    lerp(c, d, u.x),
                    u.y
                );
            }

            // ========================================================
            // WOOD TEXTURE
            // ========================================================

            float3 woodTexture(float3 localPos)
            {
                float radius =
                    sqrt(
                        localPos.x * localPos.x +
                        localPos.z * localPos.z
                    );

                float distortion =
                    noise2D(localPos.xz * 3.5)
                    * _NoiseAmp;

                float ring =
                    frac(
                        (radius + distortion) *
                        _RingScale
                    );

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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

                // Color procedural
                float3 texColor =
                    woodTexture(f.localPos);

                // Toon diffuse
                float NdotL =
                    max(0.0, dot(N, L));

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

                // Toon specular
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

                // Ambient
                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // Final
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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            float _ShadowMult;

            float _Bands;

            float4 _SpecColor2;

            float _SpecThresh;

            float _SpecSmooth;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                float3 localPos : TEXCOORD2;

                LIGHTING_COORDS(3,4)
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

                o.localPos =
                    v.vertex.xyz;

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            // ========================================================
            // NOISE
            // ========================================================

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            float noise2D(float2 p)
            {
                float2 i = floor(p);

                float2 f = frac(p);

                float2 u =
                    f * f * (3.0 - 2.0 * f);

                float a =
                    hash(i.x + i.y * 57.0);

                float b =
                    hash(i.x + 1.0 + i.y * 57.0);

                float c =
                    hash(i.x + (i.y + 1.0) * 57.0);

                float d =
                    hash(i.x + 1.0 + (i.y + 1.0) * 57.0);

                return lerp(
                    lerp(a, b, u.x),
                    lerp(c, d, u.x),
                    u.y
                );
            }

            // ========================================================
            // WOOD TEXTURE
            // ========================================================

            float3 woodTexture(float3 localPos)
            {
                float radius =
                    sqrt(
                        localPos.x * localPos.x +
                        localPos.z * localPos.z
                    );

                float distortion =
                    noise2D(localPos.xz * 3.5)
                    * _NoiseAmp;

                float ring =
                    frac(
                        (radius + distortion) *
                        _RingScale
                    );

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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

                // Attenuation automática
                LIGHT_ATTENUATION(atten, f);

                // Color procedural
                float3 texColor =
                    woodTexture(f.localPos);

                // Toon diffuse
                float NdotL =
                    max(0.0, dot(N, L));

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

                // Toon specular
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

                // Final
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

Shader "Custom/ToonShader_Texture2D"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) =
            (0.1, 0.1, 0.1, 0)

        _MainTex ("Albedo Texture (2D)", 2D) =
            "white" {}

        _ShadowMult ("Shadow Multiplier", Float) =
            0.35

        _Bands ("Toon Bands", Float) =
            3.0

        _SpecColor2 ("Specular Color", Color) =
            (1, 1, 1, 1)

        _SpecThresh ("Specular Threshold", Float) =
            0.85

        _SpecSmooth ("Specular Smoothness", Float) =
            0.02

        _OutlineColor ("Outline Color", Color) =
            (0, 0, 0, 1)

        _OutlineWidth ("Outline Width", Float) =
            0.02
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

            float _ShadowMult;
            float _Bands;

            float4 _SpecColor2;
            float _SpecThresh;
            float _SpecSmooth;

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

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                float3 H =
                    normalize(L + V);

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                float NdotL =
                    max(0.0, dot(N, L));

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

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

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

            float _ShadowMult;
            float _Bands;

            float4 _SpecColor2;
            float _SpecThresh;
            float _SpecSmooth;

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

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N =
                    normalize(f.normal_w);

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

                float atten =
                    LIGHT_ATTENUATION(f);

                float3 texColor =
                    tex2D(_MainTex, f.uv).rgb;

                float NdotL =
                    max(0.0, dot(N, L));

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