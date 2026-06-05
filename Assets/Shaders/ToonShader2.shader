

Shader "Custom/ToonShader2_MultiLight"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color) = (1,1,1,1)
        _LightPosition_w ("Light Position", Vector) = (0,5,0,1)

        // POINT LIGHT
        _PointLightIntensity ("Point Light Intensity", Color) = (1,1,1,1)
        _PointLightPosition_w ("Point Light Position", Vector) = (0,3,0,1)

        // SPOT LIGHT
        _SpotLightIntensity ("Spot Light Intensity", Color) = (1,1,1,1)
        _SpotLightPosition_w ("Spot Light Position", Vector) = (0,3,0,1)
        _SpotLightDirection ("Spot Light Direction", Vector) = (0,-1,0,0)
        _SpotAngle ("Spot Angle", Float) = 0.8

        _AmbientLight ("Ambient Light", Color) = (0.1,0.1,0.1,1)

        _MaterialKa  ("Material Ka", Vector) = (0.1,0.1,0.1,0)
        _BaseColor   ("Base Color", Color) = (0.8,0.3,0.1,1)
        _ShadowColor ("Shadow Color", Color) = (0.3,0.1,0.05,1)

        _Bands ("Toon Bands", Float) = 3.0

        _SpecColor2 ("Specular Color", Color) = (1,1,1,1)
        _SpecThresh ("Specular Threshold", Float) = 0.85
        _SpecSmooth ("Specular Smoothness", Float) = 0.02

        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth ("Outline Width", Float) = 0.02
    }

    SubShader
    {
        Tags { "RenderType" = "Opaque" }

        // =========================
        // PASS 1: TOON LIGHTING
        // =========================
        Pass
        {
            Cull Back

            CGPROGRAM
            #pragma vertex vertexShader
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
            float4 _BaseColor;
            float4 _ShadowColor;

            float _Bands;
            float4 _SpecColor2;
            float _SpecThresh;
            float _SpecSmooth;

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

            // =========================
            // FUNCION TOON (REUTILIZABLE)
            // =========================
            float3 ToonLight(float3 N, float3 V, float3 L, float3 lightColor)
            {
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));

                // cuantizacion
                float toonDiff = floor(NdotL * _Bands) / _Bands;

                float3 diffuse = lerp(_ShadowColor.rgb, _BaseColor.rgb, toonDiff);

                // especular toon
                float NdotH = max(0.0, dot(N, H));
                float specMask = smoothstep(_SpecThresh - _SpecSmooth,
                                            _SpecThresh + _SpecSmooth,
                                            NdotH);

                float3 specular = _SpecColor2.rgb * specMask;

                return lightColor * (diffuse + specular);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                // =========================
                // DIRECTIONAL
                // =========================
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 dirLight = ToonLight(N, V, L, _LightIntensity.rgb);

                // =========================
                // POINT
                // =========================
                float3 Lp = normalize(_PointLightPosition_w.xyz - f.position_w.xyz);
                float3 pointLight = ToonLight(N, V, Lp, _PointLightIntensity.rgb);

                // =========================
                // SPOT
                // =========================
                float3 Ls = normalize(_SpotLightPosition_w.xyz - f.position_w.xyz);

                float spotFactor =
                    dot(normalize(-_SpotLightDirection.xyz), Ls);

                spotFactor = step(_SpotAngle, spotFactor);

                float3 spotLight =
                    ToonLight(N, V, Ls, _SpotLightIntensity.rgb) * spotFactor;

                // =========================
                // FINAL
                // =========================
                float3 finalColor =
                    ambient +
                    dirLight +
                    pointLight +
                    spotLight;

                return float4(finalColor, 1.0);
            }

            ENDCG
        }

        // =========================
        // PASS 2: OUTLINE
        // =========================
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
                float3 expanded = v.vertex.xyz + v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(float4(expanded,1));
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
