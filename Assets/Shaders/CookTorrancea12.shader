Shader "Custom/CookTorrancea12"

{
    Properties
    {
        _LightIntensity  ("Light Intensity",       Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",         Color)  = (1, 1, 1, 1)

        // Material difuso
        _MaterialKa  ("Material Ka", Vector) = (0, 0, 0, 0) //cuanto refleja
        _AlbedoColor ("Albedo Color (rho_d)", Vector) = (0.8, 0.6, 0.1, 0) //color base 

        //Material ESPECULAR: REFLECTANCIA Y RUGORISIDAD 
        _F0        ("F0 (Fresnel reflectance)", Vector) = (0.955, 0.638, 0.538, 0)  //Reflectancia base 
        _Roughness ("Roughness (rp)",           Float)  = 0.3
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" } //no transparente

        Pass
        {     //Cull Off   // <-- agregá esta línea

            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _AlbedoColor;
            float4 _F0;
            float  _Roughness;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1; // pq la iluminacion se calcula en esp mundo
            };

            // Vertex shader: igual al de practicas anteriores
            v2f vertexShader(appdata_base v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex); //posicion en espacio mundo
                o.normal_w   = UnityObjectToWorldNormal(v.normal); //convierte normales a mundo
                return o;
            }

            
            // Fresnel - aproximacion de Schlick  --> CUANTO REFLEJA según el ángulo
            // F(v,h) = F0 + (1 - F0)(1 - dot(v,h))^5


            //pow --> potencia 
            
            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            // Funcion distribucion normal - GGX   --> 
            // D(h) = alpha^2 / (pi * ((n.h)^2*(alpha^2-1)+1)^2)
            // con alpha = roughness^2
            
            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha  = roughness * roughness;
                float alpha2 = alpha * alpha;
                float NdotH2 = NdotH * NdotH;
                float denom  = NdotH2 * (alpha2 - 1.0) + 1.0;
                return alpha2 / (UNITY_PI * denom * denom);
            }

            // Geometry Term - Smith con aproximacion Schlick-GGX
            // G1(v) = (n.v) / ((n.v)(1-k) + k)   con k = alpha/2
            // G(l,v) = G1(l) * G1(v)
            
            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha = roughness * roughness;
                float k     = alpha / 2.0;
                return NdotV / (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(float NdotL, float NdotV, float roughness)
            {
                float G1L = GeometrySchlickGGX(NdotL, roughness);
                float G1V = GeometrySchlickGGX(NdotV, roughness);
                return G1L * G1V;
            }

            // Fragment shader principal
            // I = Ia*Ka  +  Ip * (rho_d/pi + F*D*G / (4*NdotL*NdotV)) * NdotL

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // Vectores principales normalizados
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
               // if (dot(N, V) < 0) N = -N;

                float3 H = normalize(L + V);
                   


                // dot(a,b)=ax​bx​+ay​by​+az​bz​ (P calcular angulos, cosenos --> iluminación)

                // Productos punto (clampeados a 0 para evitar negativos)
                float NdotL = max(0.0, dot(N, L)); //N*L
                float NdotV = max(0.0, dot(N, V));  //N*V
                float NdotH = max(0.0, dot(N, H)); //angulo entre dire de vision y H vector 
                float VdotH = max(0.0, dot(V, H));

                // Termino ambiente: Ia * Ka
                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // Parte difusa: rho_d / pi
                float3 diffuse = _AlbedoColor.rgb;

                // Parte especular Cook-Torrance: F*D*G / (4 * NdotL * NdotV)
                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GeometrySmith(NdotL, NdotV, _Roughness);

                float3 specular = (F * D * G) / (4.0 * NdotL * NdotV + 0.001);

                // BRDF final: ambiente + Ip * (difuso + especular) * NdotL
                float3 color = ambient
                             + _LightIntensity.rgb * (diffuse + specular) * NdotL;

                fixed4 col;
                col.rgb = color;
                col.a   = 1.0;
                return col;
            }
            ENDCG
        }
    }
}

/*
Shader "Custom/CookTorrancea12"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (1, 1, 1, 1)

        // Material difuso
        _MaterialKa ("Material Ka", Vector) =
            (0, 0, 0, 0)

        _AlbedoColor ("Albedo Color (rho_d)", Vector) =
            (0.8, 0.6, 0.1, 0)

        // Material especular
        _F0 ("F0 (Fresnel reflectance)", Vector) =
            (0.955, 0.638, 0.538, 0)

        _Roughness ("Roughness (rp)", Float) = 0.3
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

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

            float4 _AlbedoColor;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;
            };

            // ========================================================
            // VERTEX SHADER
            // ========================================================

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

            float DistributionGGX(
                float NdotH,
                float roughness
            )
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

            float GeometrySchlickGGX(
                float NdotV,
                float roughness
            )
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                float G1L =
                    GeometrySchlickGGX(
                        NdotL,
                        roughness
                    );

                float G1V =
                    GeometrySchlickGGX(
                        NdotV,
                        roughness
                    );

                return G1L * G1V;
            }

            // ========================================================
            // FRAGMENT SHADER
            // ========================================================

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // Normal
                float3 N =
                    normalize(f.normal_w);

                // Luz direccional
                float3 L =
                    normalize(_WorldSpaceLightPos0.xyz);

                // Vista
                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                // Half vector
                float3 H =
                    normalize(L + V);

                // Productos punto
                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                // Ambient
                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // Difuso
                float3 diffuse =
                    _AlbedoColor.rgb;

                // Cook-Torrance
                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

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

                // Color final
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

            float4 _AlbedoColor;

            float4 _F0;

            float _Roughness;

            struct v2f
            {
                float4 position : SV_POSITION;

                float3 position_w : TEXCOORD0;

                float3 normal_w : TEXCOORD1;

                LIGHTING_COORDS(2,3)
            };

            // ========================================================
            // VERTEX SHADER
            // ========================================================

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

            float DistributionGGX(
                float NdotH,
                float roughness
            )
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

            float GeometrySchlickGGX(
                float NdotV,
                float roughness
            )
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                float G1L =
                    GeometrySchlickGGX(
                        NdotL,
                        roughness
                    );

                float G1V =
                    GeometrySchlickGGX(
                        NdotV,
                        roughness
                    );

                return G1L * G1V;
            }

            // ========================================================
            // FRAGMENT SHADER
            // ========================================================

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // Normal
                float3 N =
                    normalize(f.normal_w);

                // Point / Spot Light
                float3 L =
                    normalize(
                        _WorldSpaceLightPos0.xyz -
                        f.position_w
                    );

                // Vista
                float3 V =
                    normalize(
                        _WorldSpaceCameraPos -
                        f.position_w
                    );

                // Half vector
                float3 H =
                    normalize(L + V);

                // Attenuation automática
                LIGHT_ATTENUATION(atten, f);

                // Productos punto
                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                // Difuso
                float3 diffuse =
                    _AlbedoColor.rgb;

                // Cook-Torrance
                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

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

                // Color final
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
}
*/

/*
Shader "Custom/CookTorrancea12"
{
    Properties
    {
        _AmbientLight ("Ambient Light", Color) =
            (1, 1, 1, 1)

        // =========================
        // DIRECTIONAL LIGHT
        // =========================

        _DirLightColor ("Directional Light Color", Color) =
            (1,1,1,1)

        _DirLightDirection ("Directional Light Direction", Vector) =
            (0,-1,0,0)

        // =========================
        // POINT LIGHT
        // =========================

        _PointLightColor ("Point Light Color", Color) =
            (1,1,1,1)

        _PointLightPosition ("Point Light Position", Vector) =
            (0,5,0,1)

        // =========================
        // SPOT LIGHT
        // =========================

        _SpotLightColor ("Spot Light Color", Color) =
            (1,1,1,1)

        _SpotLightPosition ("Spot Light Position", Vector) =
            (0,5,0,1)

        _SpotLightDirection ("Spot Light Direction", Vector) =
            (0,-1,0,0)

        _SpotAngle ("Spot Angle", Float) = 0.9

        // =========================
        // MATERIAL
        // =========================

        _MaterialKa ("Material Ka", Vector) =
            (0, 0, 0, 0)

        _AlbedoColor ("Albedo Color (rho_d)", Vector) =
            (0.8, 0.6, 0.1, 0)

        _F0 ("F0 (Fresnel reflectance)", Vector) =
            (0.955, 0.638, 0.538, 0)

        _Roughness ("Roughness (rp)", Float) = 0.3
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        Pass
        {
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

            float4 _AlbedoColor;

            float4 _F0;

            float _Roughness;

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
            // COOK TORRANCE FUNCTIONS
            // ==========================================

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return
                    F0 +
                    (1.0 - F0) *
                    pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(
                float NdotH,
                float roughness
            )
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

            float GeometrySchlickGGX(
                float NdotV,
                float roughness
            )
            {
                float alpha =
                    roughness * roughness;

                float k =
                    alpha / 2.0;

                return
                    NdotV /
                    (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(
                float NdotL,
                float NdotV,
                float roughness
            )
            {
                float G1L =
                    GeometrySchlickGGX(
                        NdotL,
                        roughness
                    );

                float G1V =
                    GeometrySchlickGGX(
                        NdotV,
                        roughness
                    );

                return G1L * G1V;
            }

            // ==========================================
            // LIGHT FUNCTION
            // ==========================================

            float3 ComputeCookTorrance(
                float3 lightColor,
                float3 L,
                float3 N,
                float3 V
            )
            {
                float3 H = normalize(L + V);

                float NdotL =
                    max(0.0, dot(N, L));

                float NdotV =
                    max(0.0, dot(N, V));

                float NdotH =
                    max(0.0, dot(N, H));

                float VdotH =
                    max(0.0, dot(V, H));

                float3 diffuse =
                    _AlbedoColor.rgb;

                float3 F =
                    FresnelSchlick(_F0.rgb, VdotH);

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

                return
                    lightColor *
                    (diffuse + specular) *
                    NdotL;
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

                // =====================================
                // AMBIENT
                // =====================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // =====================================
                // DIRECTIONAL LIGHT
                // =====================================

                float3 Ld =
                    normalize(-_DirLightDirection.xyz);

                float3 directional =
                    ComputeCookTorrance(
                        _DirLightColor.rgb,
                        Ld,
                        N,
                        V
                    );

                // =====================================
                // POINT LIGHT
                // =====================================

                float3 Lp =
                    normalize(
                        _PointLightPosition.xyz -
                        f.position_w
                    );

                float3 point1 =
                    ComputeCookTorrance(
                        _PointLightColor.rgb,
                        Lp,
                        N,
                        V
                    );

                // =====================================
                // SPOT LIGHT
                // =====================================

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
                    ComputeCookTorrance(
                        _SpotLightColor.rgb * spotFactor,
                        Ls,
                        N,
                        V
                    );

                // =====================================
                // FINAL COLOR
                // =====================================

                float3 color =
                    ambient +
                    directional +
                    point1
                     +
                    spot;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
}*/
