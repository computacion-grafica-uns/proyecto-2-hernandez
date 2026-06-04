Shader "Custom/GlassBlinnPhong"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color) = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)

        // POINT LIGHT
        _PointLightIntensity  ("Point Light Intensity", Color) = (1,1,1,1)
        _PointLightPosition_w ("Point Light Position", Vector) = (0,3,0,1)

        // SPOT LIGHT
        _SpotLightIntensity  ("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,3,0,1)
        _SpotLightDirection  ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotAngle           ("Spot Angle", Float) = 0.8

        _AmbientLight ("Ambient Light", Color) = (0.1, 0.1, 0.1, 1)

        _MaterialKa ("Material Ka", Vector) = (0.05, 0.05, 0.05, 0)
        _MaterialKd ("Material Kd", Vector) = (0.15, 0.15, 0.15, 0)
        _MaterialKs ("Material Ks", Vector) = (1, 1, 1, 0)

        _Material_n ("Material n (shininess)", Float) = 128

        // Vidrio
        _GlassColor  ("Glass Tint Color", Color) = (0.8, 0.95, 1.0, 1)
        _Opacity     ("Opacity", Range(0,1)) = 0.15
        // Fresnel: controla cuanto se opaca el borde
        _FresnelPower ("Fresnel Power", Range(0.5, 10)) = 3.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        
        Pass
        {
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _PointLightIntensity;
            float4 _PointLightPosition_w;
            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float  _SpotAngle;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float  _Material_n;
            float4 _GlassColor;
            float  _Opacity;
            float  _FresnelPower;

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
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);

                // Fresnel: bordes mas opacos
                //float fresnel = pow(1.0 - abs(dot(N, V)), _FresnelPower);
               // float alpha   = saturate(_Opacity + fresnel * 0.6);
                float alpha = _Opacity;



                
                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // Luz direccional
                float3 L  = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 H  = normalize(L + V);
                float NdotL = max(0.0, dot(N, L));
                float3 diffuse  = _LightIntensity.rgb * _MaterialKd.rgb * NdotL;
                float3 specular = _LightIntensity.rgb * _MaterialKs.rgb
                                * pow(max(0.0, dot(N, H)), _Material_n) * NdotL;

                // Luz puntual
                float3 Lp    = normalize(_PointLightPosition_w.xyz - f.position_w.xyz);
                float3 Hp    = normalize(Lp + V);
                float NdotLp = max(0.0, dot(N, Lp));
                float3 diffusePoint  = _PointLightIntensity.rgb * _MaterialKd.rgb * NdotLp;
                float3 specularPoint = _PointLightIntensity.rgb * _MaterialKs.rgb
                                     * pow(max(0.0, dot(N, Hp)), _Material_n) * NdotLp;

                // Spot
                float3 Ls    = normalize(_SpotLightPosition_w.xyz - f.position_w.xyz);
                float3 Hs    = normalize(Ls + V);
                float spotFactor = step(_SpotAngle, dot(normalize(-_SpotLightDirection.xyz), Ls));
                float NdotLs = max(0.0, dot(N, Ls));
                float3 diffuseSpot  = _SpotLightIntensity.rgb * _MaterialKd.rgb * NdotLs * spotFactor;
                float3 specularSpot = _SpotLightIntensity.rgb * _MaterialKs.rgb
                                    * pow(max(0.0, dot(N, Hs)), _Material_n) * NdotLs * spotFactor;

                float3 finalColor = (ambient + diffuse + specular
                                   + diffusePoint + specularPoint
                                   + diffuseSpot  + specularSpot) * _GlassColor.rgb;
                
                                   //float3 finalColor = _GlassColor.rgb;
                return fixed4(finalColor, alpha * 0.6);
            }
            ENDCG
        }

            }
}























// =============================================
        // PASS 2: Front faces
        // =============================================
       /* Pass
        {
            Cull Back
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex   vertexShader
            #pragma fragment fragmentShader
            #include "UnityCG.cginc"

            float4 _LightIntensity;
            float4 _LightPosition_w;
            float4 _PointLightIntensity;
            float4 _PointLightPosition_w;
            float4 _SpotLightIntensity;
            float4 _SpotLightPosition_w;
            float4 _SpotLightDirection;
            float  _SpotAngle;
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _MaterialKd;
            float4 _MaterialKs;
            float  _Material_n;
            float4 _GlassColor;
            float  _Opacity;
            float  _FresnelPower;

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
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);

                float fresnel = pow(1.0 - abs(dot(N, V)), _FresnelPower);
                float alpha   = saturate(_Opacity + fresnel * 0.6);

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                float3 L  = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 H  = normalize(L + V);
                float NdotL = max(0.0, dot(N, L));
                float3 diffuse  = _LightIntensity.rgb * _MaterialKd.rgb * NdotL;
                float3 specular = _LightIntensity.rgb * _MaterialKs.rgb
                                * pow(max(0.0, dot(N, H)), _Material_n) * NdotL;

                float3 Lp    = normalize(_PointLightPosition_w.xyz - f.position_w.xyz);
                float3 Hp    = normalize(Lp + V);
                float NdotLp = max(0.0, dot(N, Lp));
                float3 diffusePoint  = _PointLightIntensity.rgb * _MaterialKd.rgb * NdotLp;
                float3 specularPoint = _PointLightIntensity.rgb * _MaterialKs.rgb
                                     * pow(max(0.0, dot(N, Hp)), _Material_n) * NdotLp;

                float3 Ls    = normalize(_SpotLightPosition_w.xyz - f.position_w.xyz);
                float3 Hs    = normalize(Ls + V);
                float spotFactor = step(_SpotAngle, dot(normalize(-_SpotLightDirection.xyz), Ls));
                float NdotLs = max(0.0, dot(N, Ls));
                float3 diffuseSpot  = _SpotLightIntensity.rgb * _MaterialKd.rgb * NdotLs * spotFactor;
                float3 specularSpot = _SpotLightIntensity.rgb * _MaterialKs.rgb
                                    * pow(max(0.0, dot(N, Hs)), _Material_n) * NdotLs * spotFactor;

                float3 finalColor = (ambient + diffuse + specular
                                   + diffusePoint + specularPoint
                                   + diffuseSpot  + specularSpot) * _GlassColor.rgb;

                return fixed4(finalColor, alpha);
            }
            ENDCG
        }*/
