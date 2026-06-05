Shader "Custom/GlassToon"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color)   = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light", Color)     = (0.1, 0.1, 0.1, 1)

        _MaterialKa  ("Material Ka",  Vector) = (0.05, 0.05, 0.05, 0)
        _BaseColor   ("Base Color",   Color)  = (0.75, 0.92, 1.0, 1)
        _ShadowColor ("Shadow Color", Color)  = (0.45, 0.65, 0.85, 1)

        _Bands       ("Toon Bands",   Float)  = 2.0

        _SpecColor2  ("Specular Color",      Color) = (1, 1, 1, 1)
        _SpecThresh  ("Specular Threshold",  Float) = 0.92
        _SpecSmooth  ("Specular Smoothness", Float) = 0.015

        // Contorno
        _OutlineColor ("Outline Color", Color) = (0.2, 0.5, 0.8, 1)
        _OutlineWidth ("Outline Width", Float) = 0.015

        // Vidrio
        _Opacity      ("Opacity", Range(0,1)) = 0.18
        _FresnelPower ("Fresnel Power", Range(0.5,10)) = 3.5
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        

       
        Pass
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
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _BaseColor;
            float4 _ShadowColor;
            float  _Bands;
            float4 _SpecColor2;
            float  _SpecThresh;
            float  _SpecSmooth;
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
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float fresnel = pow(1.0 - abs(dot(N, V)), _FresnelPower);
                float alpha   = saturate(_Opacity + fresnel * 0.55);

                float NdotL    = max(0.0, dot(N, L));
                float toonD    = floor(NdotL * _Bands) / _Bands;
                float3 diffuse = lerp(_ShadowColor.rgb, _BaseColor.rgb, toonD);

                float NdotH    = max(0.0, dot(N, H));
                float specMask = smoothstep(_SpecThresh - _SpecSmooth,
                                            _SpecThresh + _SpecSmooth, NdotH);
                float3 specular = _SpecColor2.rgb * specMask;

                float3 ambient = _AmbientLight.rgb * _MaterialKa.rgb;

                float3 color = ambient + _LightIntensity.rgb * (diffuse + specular);

                return fixed4(color, alpha);
            }
            ENDCG
        }

        // =============================================
        // PASS 3: Contorno toon (outline)
        // Se usa Cull Front para ver caras traseras expandidas
        // Color semitransparente para que no tape demasiado
        // =============================================
        Pass
        {
            Cull Front
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

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
                float3 expandedPos = v.vertex.xyz + v.normal * _OutlineWidth;
                o.position = UnityObjectToClipPos(float4(expandedPos, 1.0));
                return o;
            }

            fixed4 outlineFrag(v2f_outline f) : SV_Target
            {
                // Outline semitransparente para no romper el efecto vidrio
                return fixed4(_OutlineColor.rgb, 0.5);
            }
            ENDCG
        }
    }
}
