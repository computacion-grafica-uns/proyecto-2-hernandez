Shader "Custom/CookTorrance_NormalMap"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa      ("Material Ka",            Vector) = (0.1, 0.1, 0.1, 0)

        _MainTex    ("Albedo Texture",  2D) = "white" {}
        _NormalMap  ("Normal Map",      2D) = "bump"  {}  // "bump" = normal plana por defecto
        _NormalScale("Normal Scale",   Float) = 1.0      // intensidad del bump

        _F0        ("F0 (Fresnel)",  Vector) = (0.04, 0.04, 0.04, 0)
        _Roughness ("Roughness",     Float)  = 0.4
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
            
            Tags { "LightMode"="ForwardBase" } //new
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
            float4    _F0;
            float     _Roughness;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float2 uv         : TEXCOORD1;

                // Matriz TBN para transformar la normal del normal map a espacio mundo
                // T = tangente, B = bitangente, N = normal
                // Cada componente es un float3 en espacio mundo
                float3 T_w : TEXCOORD2;
                float3 B_w : TEXCOORD3;
                float3 N_w : TEXCOORD4;
            };

            // appdata_tan incluye tangentes del mesh (necesarias para TBN)
            v2f vertexShader(appdata_tan v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.uv         = TRANSFORM_TEX(v.texcoord, _MainTex);

                // Normal en espacio mundo
                float3 N = UnityObjectToWorldNormal(v.normal);

                // Tangente en espacio mundo
                // v.tangent.w es el signo de la bitangente (puede ser +1 o -1)
                float3 T = UnityObjectToWorldDir(v.tangent.xyz);

                // Bitangente = cross(N, T) * signo
                // El signo (v.tangent.w) corrige la orientacion segun el UV unwrap
                float3 B = cross(N, T) * v.tangent.w;

                o.T_w = T;
                o.B_w = B;
                o.N_w = N;

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
                float denom  = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
                return alpha2 / (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotX, float roughness)
            {
                float k = (roughness * roughness) / 2.0;
                return NdotX / (NdotX * (1.0 - k) + k);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // -----------------------------------------------
                // NORMAL MAPPING
                // -----------------------------------------------
                // 1. Leer la normal del mapa (viene en espacio tangente)
                //    Los normal maps guardan vectores como colores RGB en [0,1]
                //    Hay que descomprimirlos a [-1,1]
                float3 normalTS = UnpackNormal(tex2D(_NormalMap, f.uv));

                // 2. Aplicar escala (intensidad del bump)
                normalTS.xy *= _NormalScale;
                normalTS = normalize(normalTS);

                // 3. Transformar de espacio tangente a espacio mundo usando la matriz TBN
                //    N_world = T*normalTS.x + B*normalTS.y + N*normalTS.z
                float3 T = normalize(f.T_w);
                float3 B = normalize(f.B_w);
                float3 N = normalize(f.N_w);
                float3 worldNormal = normalize(T * normalTS.x + B * normalTS.y + N * normalTS.z);
                // -----------------------------------------------

                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                // Usamos worldNormal (mapeada) en vez de N original
                float NdotL = max(0.0, dot(worldNormal, L));
                float NdotV = max(0.0, dot(worldNormal, V));
                float NdotH = max(0.0, dot(worldNormal, H));
                float VdotH = max(0.0, dot(V, H));

                float3 albedo   = tex2D(_MainTex, f.uv).rgb;
                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;

                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GeometrySchlickGGX(NdotL, _Roughness)
                         * GeometrySchlickGGX(NdotV, _Roughness);

                float3 specular = (F * D * G) / (4.0 * NdotL * NdotV + 0.001);

                float3 color = ambient
                             + _LightIntensity.rgb * (albedo + specular) * NdotL;

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
}


/*
Shader "Custom/CookTorrance_NormalMap"
{
    Properties
    {
        _AmbientLight ("Ambient Light",  Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa   ("Material Ka",   Vector)  = (0.1, 0.1, 0.1, 0)
        _MainTex      ("Albedo Texture", 2D)     = "white" {}
        _NormalMap    ("Normal Map",     2D)     = "bump"  {}
        _NormalScale  ("Normal Scale",   Float)  = 1.0
        _F0           ("F0 (Fresnel)",  Vector)  = (0.04, 0.04, 0.04, 0)
        _Roughness    ("Roughness",      Float)  = 0.4
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
            #pragma multi_compile_fwdbase   // genera variantes para sombras/luces
            #include "UnityCG.cginc"
                        #include "Lighting.cginc"

            #include "AutoLight.cginc"

            float4    _AmbientLight;
            float4    _MaterialKa;
            sampler2D _MainTex;   float4 _MainTex_ST;
            sampler2D _NormalMap; float4 _NormalMap_ST;
            float     _NormalScale;
            float4    _F0;
            float     _Roughness;

            struct v2f {
                float4 pos    : SV_POSITION;
                float3 wpos   : TEXCOORD0;
                float2 uv     : TEXCOORD1;
                float3 T_w    : TEXCOORD2;
                float3 B_w    : TEXCOORD3;
                float3 N_w    : TEXCOORD4;
            };

            v2f vert(appdata_tan v)
            {
                v2f o;
                o.pos  = UnityObjectToClipPos(v.vertex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv   = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 N = UnityObjectToWorldNormal(v.normal);
                float3 T = UnityObjectToWorldDir(v.tangent.xyz);
                float3 B = cross(N, T) * v.tangent.w;
                o.T_w = T; o.B_w = B; o.N_w = N;
                return o;
            }

            // ── funciones CT ────────────────────────────────────────────────
            float3 FresnelSchlick(float3 F0, float VdotH){
                return F0 + (1-F0)*pow(1-VdotH,5);
            }
            float DistributionGGX(float NdotH, float r){
                float a=r*r, a2=a*a;
                float d=NdotH*NdotH*(a2-1)+1;
                return a2/(UNITY_PI*d*d);
            }
            float GSchlick(float NdotX, float r){
                float k=r*r/2;
                return NdotX/(NdotX*(1-k)+k);
            }

            float3 CookTorrance(float3 N, float3 L, float3 V, float3 albedo, float3 lightColor)
            {
                float3 H    = normalize(L+V);
                float NdotL = max(0,dot(N,L));
                float NdotV = max(0,dot(N,V));
                float NdotH = max(0,dot(N,H));
                float VdotH = max(0,dot(V,H));

                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GSchlick(NdotL,_Roughness)*GSchlick(NdotV,_Roughness);

                float3 spec = (F*D*G)/(4*NdotL*NdotV+0.001);
                return lightColor * (albedo + spec) * NdotL;
            }
            // ────────────────────────────────────────────────────────────────

            fixed4 frag(v2f f) : SV_Target
            {
                // Normal mapping
                float3 normalTS = UnpackNormal(tex2D(_NormalMap, f.uv));
                normalTS.xy *= _NormalScale;
                float3 T = normalize(f.T_w);
                float3 B = normalize(f.B_w);
                float3 N = normalize(f.N_w);
                float3 worldN = normalize(T*normalTS.x + B*normalTS.y + N*normalTS.z);

                float3 albedo = tex2D(_MainTex, f.uv).rgb;
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);

                // _WorldSpaceLightPos0 = dirección de la luz direccional
                // Si es direccional, .w == 0 y .xyz ya es la dirección
                float3 L = normalize(_WorldSpaceLightPos0.xyz);
                float3 lightColor = _LightColor0.rgb;  // color/intensidad real de Unity

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb * albedo;
                float3 color   = ambient + CookTorrance(worldN, L, V, albedo, lightColor);

                return fixed4(color, 1);
            }
            ENDCG
        }

        // ── PASS 2: luces adicionales (Point + Spot) ───────────────────────
        Pass
        {
            Tags { "LightMode"="ForwardAdd" }
            Blend One One   // suma encima del pass anterior
            CGPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #pragma multi_compile_fwdadd
            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            sampler2D _MainTex;   float4 _MainTex_ST;
            sampler2D _NormalMap; float4 _NormalMap_ST;
            float     _NormalScale;
            float4    _F0;
            float     _Roughness;

            struct v2f {
                float4 pos  : SV_POSITION;
                float3 wpos : TEXCOORD0;
                float2 uv   : TEXCOORD1;
                float3 T_w  : TEXCOORD2;
                float3 B_w  : TEXCOORD3;
                float3 N_w  : TEXCOORD4;
            };

            v2f vert(appdata_tan v)
            {
                v2f o;
                o.pos  = UnityObjectToClipPos(v.vertex);
                o.wpos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv   = TRANSFORM_TEX(v.texcoord, _MainTex);
                float3 N = UnityObjectToWorldNormal(v.normal);
                float3 T = UnityObjectToWorldDir(v.tangent.xyz);
                float3 B = cross(N, T) * v.tangent.w;
                o.T_w=T; o.B_w=B; o.N_w=N;
                return o;
            }

            float3 FresnelSchlick(float3 F0,float VdotH){ return F0+(1-F0)*pow(1-VdotH,5); }
            float DistributionGGX(float NdotH,float r){ float a=r*r,a2=a*a,d=NdotH*NdotH*(a2-1)+1; return a2/(UNITY_PI*d*d); }
            float GSchlick(float NdotX,float r){ float k=r*r/2; return NdotX/(NdotX*(1-k)+k); }

            fixed4 frag(v2f f) : SV_Target
            {
                float3 normalTS = UnpackNormal(tex2D(_NormalMap, f.uv));
                normalTS.xy *= _NormalScale;
                float3 T=normalize(f.T_w), B=normalize(f.B_w), N=normalize(f.N_w);
                float3 worldN = normalize(T*normalTS.x+B*normalTS.y+N*normalTS.z);

                float3 albedo = tex2D(_MainTex, f.uv).rgb;
                float3 V = normalize(_WorldSpaceCameraPos - f.wpos);

                // Para Point/Spot: _WorldSpaceLightPos0.w == 1, necesitás restar
                float3 L = normalize(_WorldSpaceLightPos0.xyz - f.wpos * _WorldSpaceLightPos0.w);

                float3 H    = normalize(L+V);
                float NdotL = max(0,dot(worldN,L));
                float NdotV = max(0,dot(worldN,V));
                float NdotH = max(0,dot(worldN,H));
                float VdotH = max(0,dot(V,H));

                float3 F = FresnelSchlick(_F0.rgb,VdotH);
                float  D = DistributionGGX(NdotH,_Roughness);
                float  G = GSchlick(NdotL,_Roughness)*GSchlick(NdotV,_Roughness);
                float3 spec = (F*D*G)/(4*NdotL*NdotV+0.001);

                float3 color = _LightColor0.rgb*(albedo+spec)*NdotL;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}*/


/*
Shader "Custom/CookTorrance_NormalMap"
{
    Properties
    {
        _AmbientLight ("Ambient Light",  Color)  = (0.1, 0.1, 0.1, 1)
        _MaterialKa   ("Material Ka",   Vector)  = (0.1, 0.1, 0.1, 0)

        _MainTex      ("Albedo Texture", 2D)     = "white" {}
        _NormalMap    ("Normal Map",     2D)     = "bump"  {}

        _NormalScale  ("Normal Scale",   Float)  = 1.0

        _F0           ("F0 (Fresnel)",  Vector)  = (0.04, 0.04, 0.04, 0)

        _Roughness    ("Roughness",      Float)  = 0.4
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        // ============================================================
        // PASS 1 → DIRECTIONAL LIGHT
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 pos    : SV_POSITION;
                float3 wpos   : TEXCOORD0;
                float2 uv     : TEXCOORD1;
                float3 T_w    : TEXCOORD2;
                float3 B_w    : TEXCOORD3;
                float3 N_w    : TEXCOORD4;
            };

            v2f vert(appdata_tan v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
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

            // ========================================================
            // COOK TORRANCE FUNCTIONS
            // ========================================================

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1 - F0) *
                    pow(1 - VdotH, 5);
            }

            float DistributionGGX(float NdotH, float r)
            {
                float a = r * r;

                float a2 = a * a;

                float d =
                    NdotH * NdotH * (a2 - 1) + 1;

                return
                    a2 /
                    (UNITY_PI * d * d);
            }

            float GSchlick(float NdotX, float r)
            {
                float k =
                    r * r / 2;

                return
                    NdotX /
                    (NdotX * (1 - k) + k);
            }

            float3 CookTorrance
            (
                float3 N,
                float3 L,
                float3 V,
                float3 albedo,
                float3 lightColor
            )
            {
                float3 H =
                    normalize(L + V);

                float NdotL =
                    max(0, dot(N, L));

                float NdotV =
                    max(0, dot(N, V));

                float NdotH =
                    max(0, dot(N, H));

                float VdotH =
                    max(0, dot(V, H));

                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

                float D =
                    DistributionGGX(NdotH, _Roughness);

                float G =
                    GSchlick(NdotL, _Roughness) *
                    GSchlick(NdotV, _Roughness);

                float3 spec =
                    (F * D * G) /
                    (4 * NdotL * NdotV + 0.001);

                return
                    lightColor *
                    (albedo + spec) *
                    NdotL;
            }

            // ========================================================
            // FRAGMENT
            // ========================================================

            fixed4 frag(v2f f) : SV_Target
            {
                // NORMAL MAP

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;

                float3 T =
                    normalize(f.T_w);

                float3 B =
                    normalize(f.B_w);

                float3 N =
                    normalize(f.N_w);

                float3 worldN =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ALBEDO

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                // VIEW

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos - f.wpos
                    );

                // DIRECTIONAL LIGHT

                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb *
                    albedo;

                float3 color =
                    ambient +
                    CookTorrance(
                        worldN,
                        L,
                        V,
                        albedo,
                        _LightColor0.rgb
                    );

                return fixed4(color, 1);
            }

            ENDCG
        }

        // ============================================================
        // PASS 2 → POINT + SPOT LIGHTS
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

            sampler2D _MainTex;
            float4 _MainTex_ST;

            sampler2D _NormalMap;
            float4 _NormalMap_ST;

            float _NormalScale;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 pos  : SV_POSITION;
                float3 wpos : TEXCOORD0;
                float2 uv   : TEXCOORD1;
                float3 T_w  : TEXCOORD2;
                float3 B_w  : TEXCOORD3;
                float3 N_w  : TEXCOORD4;

                LIGHTING_COORDS(5,6)
            };

            v2f vert(appdata_tan v)
            {
                v2f o;

                o.pos =
                    UnityObjectToClipPos(v.vertex);

                o.wpos =
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

            // ========================================================
            // COOK TORRANCE FUNCTIONS
            // ========================================================

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1 - F0) *
                    pow(1 - VdotH, 5);
            }

            float DistributionGGX(float NdotH, float r)
            {
                float a = r * r;

                float a2 = a * a;

                float d =
                    NdotH * NdotH * (a2 - 1) + 1;

                return
                    a2 /
                    (UNITY_PI * d * d);
            }

            float GSchlick(float NdotX, float r)
            {
                float k =
                    r * r / 2;

                return
                    NdotX /
                    (NdotX * (1 - k) + k);
            }

            // ========================================================
            // FRAGMENT
            // ========================================================

            fixed4 frag(v2f f) : SV_Target
            {
                // NORMAL MAP

                float3 normalTS =
                    UnpackNormal(
                        tex2D(_NormalMap, f.uv)
                    );

                normalTS.xy *= _NormalScale;

                float3 T =
                    normalize(f.T_w);

                float3 B =
                    normalize(f.B_w);

                float3 N =
                    normalize(f.N_w);

                float3 worldN =
                    normalize(
                        T * normalTS.x +
                        B * normalTS.y +
                        N * normalTS.z
                    );

                // ALBEDO

                float3 albedo =
                    tex2D(_MainTex, f.uv).rgb;

                // VIEW

                float3 V =
                    normalize(
                        _WorldSpaceCameraPos - f.wpos
                    );

                // POINT / SPOT LIGHT

                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.wpos
                    );

                float3 H =
                    normalize(L + V);

                // ATTENUATION

                LIGHT_ATTENUATION(atten, f);

                float NdotL =
                    max(0, dot(worldN, L));

                float NdotV =
                    max(0, dot(worldN, V));

                float NdotH =
                    max(0, dot(worldN, H));

                float VdotH =
                    max(0, dot(V, H));

                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

                float D =
                    DistributionGGX(NdotH, _Roughness);

                float G =
                    GSchlick(NdotL, _Roughness) *
                    GSchlick(NdotV, _Roughness);

                float3 spec =
                    (F * D * G) /
                    (4 * NdotL * NdotV + 0.001);

                float3 color =
                    _LightColor0.rgb *
                    (albedo + spec) *
                    NdotL *
                    atten;

                return fixed4(color, 1);
            }

            ENDCG
        }
    }
}*/