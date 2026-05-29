/*Shader "Custom/BlinnPhong10"
{
    Properties
    {
        _LightIntensity  ("Light Intensity",        Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)",  Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light",          Color)  = (1, 1, 1, 1)

        _MaterialKa ("Material Ka", Vector) = (0, 0, 0, 0)
        _MaterialKd ("Material Kd", Vector) = (0, 0, 0, 0)
        _MaterialKs ("Material Ks", Vector) = (0, 0, 0, 0)
        _Material_n ("Material n (shininess)", Float) = 0.5
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        //OJO AGREGUE ESTAS DOS LINEAS ABAJO 
        //Blend SrcAlpha OneMinusSrcAlpha
        //ZWrite Off
        Pass
        {
            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float  _Material_n;

            struct v2f
            {
                float4 position   : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w   : TEXCOORD1;
            };

            // Vertex shader: igual al de la practica 9
            v2f vertexShader(appdata_base v)
            {
                v2f o;
                o.position   = UnityObjectToClipPos(v.vertex);
                o.position_w = mul(unity_ObjectToWorld, v.vertex);
                o.normal_w   = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            // Fragment shader: Blinn-Phong
            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // Vectores N, L, V normalizados
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);

                // BLINN-PHONG: vector halfway H = normalize(L + V)
                // En Phong usabamos: R = reflect(-L, N)  y  pow(dot(R,V), n)
                // Aqui usamos:       H = normalize(L + V) y  pow(dot(N,H), n)
                float3 H = normalize(L + V);

                // Termino ambiente: Ia * Ka
                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // Termino difuso: Ip * Kd * max(0, N.L)
                float3 diffuse = _LightIntensity.rgb * _MaterialKd.rgb
                               * max(0.0, dot(N, L));

                // Termino especular Blinn-Phong: Ip * Ks * max(0, N.H)^n
                //float3 specular = _LightIntensity.rgb * _MaterialKs.rgb  * pow(max(0.0, dot(N, H)), _Material_n);

               //float3 specular = 0;

//if (dot(N, L) > 0.0)
//{
 //   specular = _LightIntensity.rgb * _MaterialKs.rgb
             * pow(max(0.0, dot(N, H)), _Material_n);
//}




float3 specular = _LightIntensity.rgb * _MaterialKs.rgb
                * pow(max(0.0, dot(N, H)), _Material_n)
                * max(0.0, dot(N, L)); 

               fixed4 col;
                col.rgb = ambient + diffuse + specular;
                col.a   = 1.0;
                return col;


                //fixed4 col; 
                col.rgb=0;
                //col.rgb = ambient ;
               //ol.rgb += diffuse;
                col.rgb +=  specular;
                col.a   = 1.0;
                return col;
            }
            ENDCG
        }
    }
}*/


Shader "Custom/BlinnPhong10"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color) = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)

        // POINT LIGHT
        _PointLightIntensity ("Point Light Intensity", Color) = (1,1,1,1)
        _PointLightPosition_w ("Point Light Position", Vector) = (0,3,0,1)

        // SPOT LIGHT
        _SpotLightIntensity ("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,3,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotAngle ("Spot Angle", Float) = 0.8

        _AmbientLight ("Ambient Light", Color) = (1, 1, 1, 1)

        _MaterialKa ("Material Ka", Vector) = (0, 0, 0, 0)
        _MaterialKd ("Material Kd", Vector) = (0, 0, 0, 0)
        _MaterialKs ("Material Ks", Vector) = (0, 0, 0, 0)

        _Material_n ("Material n (shininess)", Float) = 0.5
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

            float4 _LightIntensity;
            float4 _LightPosition_w;

            // POINT LIGHT
            float4 _PointLightIntensity;
            float4 _PointLightPosition_w;

            // SPOT LIGHT
            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float  _SpotAngle;

            float4 _AmbientLight;

            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;

            float _Material_n;

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 position_w : TEXCOORD0;
                float3 normal_w : TEXCOORD1;
            };

            v2f vertexShader(appdata_base v)
            {
                v2f o;

                o.position =
                    UnityObjectToClipPos(v.vertex);

                o.position_w =
                    mul(unity_ObjectToWorld, v.vertex);

                o.normal_w =
                    UnityObjectToWorldNormal(v.normal);

                return o;
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                // =========================
                // NORMAL
                // =========================

                float3 N =
                    normalize(f.normal_w);

                float3 V =
                    normalize(_WorldSpaceCameraPos - f.position_w.xyz);

                // ====================================================
                // DIRECTIONAL LIGHT
                // ====================================================

                float3 L =
                    normalize(_LightPosition_w.xyz - f.position_w.xyz);

                float3 H =
                    normalize(L + V);

                float NdotL =
                    max(0.0, dot(N, L));

                float3 diffuse =
                    _LightIntensity.rgb *
                    _MaterialKd.rgb *
                    NdotL;

                float3 specular =
                    _LightIntensity.rgb *
                    _MaterialKs.rgb *
                    pow(max(0.0, dot(N, H)), _Material_n)
                    * NdotL;

                // ====================================================
                // POINT LIGHT
                // ====================================================

                float3 Lp =
                    normalize(_PointLightPosition_w.xyz - f.position_w.xyz);

                float3 Hp =
                    normalize(Lp + V);

                float NdotLp =
                    max(0.0, dot(N, Lp));

                float3 diffusePoint =
                    _PointLightIntensity.rgb *
                    _MaterialKd.rgb *
                    NdotLp;

                float3 specularPoint =
                    _PointLightIntensity.rgb *
                    _MaterialKs.rgb *
                    pow(max(0.0, dot(N, Hp)), _Material_n)
                    * NdotLp;

                // ====================================================
                // SPOT LIGHT
                // ====================================================

                float3 Ls =
                    normalize(_SpotLightPosition_w.xyz - f.position_w.xyz);

                float3 Hs =
                    normalize(Ls + V);

                float spotFactor =
                    dot(
                        normalize(-_SpotLightDirection.xyz),
                        Ls
                    );

                spotFactor =
                    step(_SpotAngle, spotFactor);

                float NdotLs =
                    max(0.0, dot(N, Ls));

                float3 diffuseSpot =
                    _SpotLightIntensity.rgb *
                    _MaterialKd.rgb *
                    NdotLs *
                    spotFactor;

                float3 specularSpot =
                    _SpotLightIntensity.rgb *
                    _MaterialKs.rgb *
                    pow(max(0.0, dot(N, Hs)), _Material_n)
                    * NdotLs
                    * spotFactor;

                // ====================================================
                // AMBIENT
                // ====================================================

                float3 ambient =
                    _AmbientLight.rgb *
                    _MaterialKa.rgb;

                // ====================================================
                // FINAL COLOR
                // ====================================================

                float3 finalColor =
                    ambient +
                    diffuse +
                    specular +
                    diffusePoint +
                    specularPoint +
                    diffuseSpot +
                    specularSpot;

                fixed4 col;

                col.rgb = finalColor;
                col.a = 1.0;

                return col;
            }

            ENDCG
        }
    }
}