Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)

        // POINT LIGHT //nuevo
        _PointLightIntensity ("Point Light Intensity", Color) = (1,1,1,1)
        _PointLightPosition_w ("Point Light Position", Vector) = (0,3,0,1)

        _AmbientLight    ("Ambient Light",          Color)  = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)
        _MaterialKs ("Material Ks", Vector) = (0.4, 0.4, 0.4, 0)
        _Material_n ("Material n",  Float)  = 32

        _ColorA    ("Color A (anillo claro)", Color) = (0.85, 0.55, 0.25, 1)
        _ColorB    ("Color B (anillo oscuro)",Color) = (0.45, 0.22, 0.08, 1)
        _RingScale ("Ring Scale",            Float) = 8.0
        _NoiseAmp  ("Noise Amplitude",       Float) = 0.15
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

            float4 _LightIntensity;
            float4 _LightPosition_w;


             float4 _PointLightIntensity; //nuevix2
            float4 _PointLightPosition_w;


            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKs;
            float  _Material_n;
            float4 _ColorA;
            float4 _ColorB;
            float  _RingScale;
            float  _NoiseAmp;

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

            float hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

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
                float radius     = sqrt(localPos.x * localPos.x + localPos.z * localPos.z);
                float distortion = noise2D(localPos.xz * 3.5) * _NoiseAmp;
                float ring       = frac((radius + distortion) * _RingScale);
                float smooth_ring = smoothstep(0.45, 0.55, ring);
                return lerp(_ColorA.rgb, _ColorB.rgb, smooth_ring);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float3 Kd = woodTexture(f.localPos);

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse  = _LightIntensity.rgb * Kd * max(0.0, dot(N, L));
                float3 specular = _LightIntensity.rgb * _MaterialKs.rgb
                                * pow(max(0.0, dot(N, H)), _Material_n)
                                * max(0.0, dot(N, L));

                return fixed4(ambient + diffuse + specular, 1.0);


                //nuevo

                
            }


            



            ENDCG
        }
    }
}



/*

Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light",  Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa   ("Material Ka",   Vector)  = (0.1, 0.1, 0.1, 0)
        _MaterialKs   ("Material Ks",   Vector)  = (0.5, 0.5, 0.5, 0)
        _Material_n   ("Material n",    Float)   = 64

        // Textura procedural: anillos de madera
        _ColorA    ("Color A (anillo claro)", Color) = (0.85, 0.55, 0.25, 1)
        _ColorB    ("Color B (anillo oscuro)",Color) = (0.45, 0.22, 0.08, 1)
        _RingScale ("Ring Scale",            Float) = 8.0
        _NoiseAmp  ("Noise Amplitude",       Float) = 0.15
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

            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKs;
            float  _Material_n;
            float4 _ColorA;
            float4 _ColorB;
            float  _RingScale;
            float  _NoiseAmp;

            struct v2f {
                float4 pos      : SV_POSITION;
                float3 wpos     : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float3 localPos : TEXCOORD2;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos      = UnityObjectToClipPos(v.vertex);
                o.wpos     = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.localPos = v.vertex.xyz;
                return o;
            }

            // ── Textura procedural de madera ──────────────────────────────
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
                float radius     = sqrt(localPos.x * localPos.x + localPos.z * localPos.z);
                float distortion = noise2D(localPos.xz * 3.5) * _NoiseAmp;
                float ring       = frac((radius + distortion) * _RingScale);
                float smoothRing = smoothstep(0.45, 0.55, ring);
                return lerp(_ColorA.rgb, _ColorB.rgb, smoothRing);
            }
            // ─────────────────────────────────────────────────────────────

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz); // direccional: w==0
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);
                float3 H = normalize(L + V);

                float3 Kd = woodTexture(f.localPos);
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

            float4 _MaterialKs;
            float  _Material_n;
            float4 _ColorA;
            float4 _ColorB;
            float  _RingScale;
            float  _NoiseAmp;

            struct v2f {
                float4 pos      : SV_POSITION;
                float3 wpos     : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float3 localPos : TEXCOORD2;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos      = UnityObjectToClipPos(v.vertex);
                o.wpos     = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal   = UnityObjectToWorldNormal(v.normal);
                o.localPos = v.vertex.xyz;
                return o;
            }

            float hash(float n) { return frac(sin(n) * 43758.5453123); }
            float noise2D(float2 p)
            {
                float2 i = floor(p); float2 f = frac(p);
                float2 u = f * f * (3.0 - 2.0 * f);
                float a = hash(i.x       + i.y * 57.0);
                float b = hash(i.x + 1.0 + i.y * 57.0);
                float c = hash(i.x       + (i.y + 1.0) * 57.0);
                float d = hash(i.x + 1.0 + (i.y + 1.0) * 57.0);
                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }
            float3 woodTexture(float3 localPos)
            {
                float radius     = sqrt(localPos.x * localPos.x + localPos.z * localPos.z);
                float distortion = noise2D(localPos.xz * 3.5) * _NoiseAmp;
                float ring       = frac((radius + distortion) * _RingScale);
                return lerp(_ColorA.rgb, _ColorB.rgb, smoothstep(0.45, 0.55, ring));
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal);
                float3 L = normalize(_WorldSpaceLightPos0.xyz - f.wpos * _WorldSpaceLightPos0.w);
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);
                float3 H = normalize(L + V);

                float3 Kd = woodTexture(f.localPos);
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
Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)

        _MaterialKs ("Material Ks", Vector) = (0.5, 0.5, 0.5, 0)

        _Material_n ("Material n", Float) = 64

        // Textura procedural madera
        _ColorA ("Color A (anillo claro)", Color) =
            (0.85, 0.55, 0.25, 1)

        _ColorB ("Color B (anillo oscuro)", Color) =
            (0.45, 0.22, 0.08, 1)

        _RingScale ("Ring Scale", Float) = 8.0

        _NoiseAmp ("Noise Amplitude", Float) = 0.15
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → LUZ DIRECCIONAL + AMBIENT
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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float3 localPos : TEXCOORD2;
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.localPos =
                    v.vertex.xyz;

                return o;
            }

            // ========================================================
            // RUIDO PROCEDURAL
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
            // TEXTURA MADERA
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
                    frac((radius + distortion) * _RingScale);

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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
                    woodTexture(f.localPos);

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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float3 localPos : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.localPos =
                    v.vertex.xyz;

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            // ========================================================
            // RUIDO PROCEDURAL
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
            // TEXTURA MADERA
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
                    frac((radius + distortion) * _RingScale);

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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
                    woodTexture(f.localPos);

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
                    NdotL *atten; //*atten

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL *atten ; //*atten

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
Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)

        _MaterialKs ("Material Ks", Vector) = (0.5, 0.5, 0.5, 0)

        _Material_n ("Material n", Float) = 64

        // Textura procedural madera
        _ColorA ("Color A (anillo claro)", Color) =
            (0.85, 0.55, 0.25, 1)

        _ColorB ("Color B (anillo oscuro)", Color) =
            (0.45, 0.22, 0.08, 1)

        _RingScale ("Ring Scale", Float) = 8.0

        _NoiseAmp ("Noise Amplitude", Float) = 0.15
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → LUZ DIRECCIONAL + AMBIENT
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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float3 localPos : TEXCOORD2;
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.localPos =
                    v.vertex.xyz;

                return o;
            }

            // ========================================================
            // RUIDO PROCEDURAL
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
            // TEXTURA MADERA
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
                    frac((radius + distortion) * _RingScale);

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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
                    woodTexture(f.localPos);

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

            float4 _ColorA;

            float4 _ColorB;

            float _RingScale;

            float _NoiseAmp;

            struct v2f
            {
                float4 pos : SV_POSITION;

                float3 wpos : TEXCOORD0;

                float3 normal : TEXCOORD1;

                float3 localPos : TEXCOORD2;

                LIGHTING_COORDS(3,4)
            };

            v2f vert(appdata_base v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
                    mul(unity_ObjectToWorld, v.vertex).xyz;

                o.normal =
                    UnityObjectToWorldNormal(v.normal);

                o.localPos =
                    v.vertex.xyz;

                // IMPORTANTE
                TRANSFER_VERTEX_TO_FRAGMENT(o);

                return o;
            }

            // ========================================================
            // RUIDO PROCEDURAL
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
            // TEXTURA MADERA
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
                    frac((radius + distortion) * _RingScale);

                float smoothRing =
                    smoothstep(0.45, 0.55, ring);

                return lerp(
                    _ColorA.rgb,
                    _ColorB.rgb,
                    smoothRing
                );
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
                    woodTexture(f.localPos);

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
                    NdotL *atten; //*atten

                // Specular
                float3 specular =
                    lightColor *
                    _MaterialKs.rgb *
                    pow(NdotH, _Material_n) *
                    NdotL *atten ; //*atten

                return fixed4(
                    diffuse + specular,
                    1.0
                );
            }

            ENDCG
        }
    }
}*/

/*
Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light", Color)  = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.1, 0.1, 0.1, 0)
        _MaterialKs ("Material Ks", Vector) = (0.4, 0.4, 0.4, 0)
        _Material_n ("Material n", Float)  = 32

        _ColorA    ("Color A (anillo claro)", Color) = (0.85, 0.55, 0.25, 1)
        _ColorB    ("Color B (anillo oscuro)", Color) = (0.45, 0.22, 0.08, 1)
        _RingScale ("Ring Scale", Float) = 8.0
        _NoiseAmp  ("Noise Amplitude", Float) = 0.15
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKs;
            float  _Material_n;
            float4 _ColorA;
            float4 _ColorB;
            float  _RingScale;
            float  _NoiseAmp;

            struct v2f
            {
                float4 pos        : SV_POSITION;
                float3 pos_w      : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
                float3 localPos   : TEXCOORD2;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos      = UnityObjectToClipPos(v.vertex);
                o.pos_w    = mul(unity_ObjectToWorld, v.vertex).xyz;
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

                return lerp(lerp(a, b, u.x), lerp(c, d, u.x), u.y);
            }

            float3 woodTexture(float3 localPos)
            {
                float radius = sqrt(localPos.x * localPos.x + localPos.z * localPos.z);
                float distortion = noise2D(localPos.xz * 3.5) * _NoiseAmp;
                float ring = frac((radius + distortion) * _RingScale);
                float smoothRing = smoothstep(0.45, 0.55, ring);

                return lerp(_ColorA.rgb, _ColorB.rgb, smoothRing);
            }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.pos_w);
                float3 V = normalize(_WorldSpaceCameraPos - f.pos_w);
                float3 H = normalize(L + V);

                float3 Kd = woodTexture(f.localPos);

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse = _LightIntensity.rgb * Kd * max(0.0, dot(N, L));
                float3 specular = _LightIntensity.rgb * _MaterialKs.rgb *
                                   pow(max(0.0, dot(N, H)), _Material_n) *
                                   max(0.0, dot(N, L));

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
}*/

/*
Shader "Custom/BlinnPhong_Procedural"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) = (0.1,0.1,0.1,1)
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float4 _AmbientLight;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return _AmbientLight;
            }

            ENDCG
        }
    }
}*/