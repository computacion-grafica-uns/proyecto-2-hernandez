Shader "Custom/GlassCookTorrance"
{
    Properties
    {
        _LightIntensity  ("Light Intensity", Color)  = (1, 1, 1, 1)
        _LightPosition_w ("Light Position (World)", Vector) = (0, 5, 0, 1)
        _AmbientLight    ("Ambient Light", Color)    = (0.1, 0.1, 0.1, 1)

        _MaterialKa  ("Material Ka", Vector) = (0.05, 0.05, 0.05, 0)

        // Vidrio: albedo casi nulo, F0 alto (refleja mucho como dielectrico)
        _AlbedoColor ("Albedo Color (rho_d)", Vector) = (0.02, 0.02, 0.02, 0)
        _F0          ("F0 (Fresnel reflectance)", Vector) = (0.04, 0.04, 0.04, 0)
        _Roughness   ("Roughness", Float) = 0.05

        // Vidrio
        _GlassColor   ("Glass Tint Color", Color) = (0.8, 0.95, 1.0, 1)
        _Opacity      ("Opacity", Range(0,1)) = 0.12
        _FresnelPower ("Fresnel Power", Range(0.5,10)) = 4.0
    }

    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }

        // =============================================
        // PASS 1: Back faces
        // =============================================
       /* Pass
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
            float4 _AmbientLight;
            float4 _MaterialKa;
            float4 _AlbedoColor;
            float4 _F0;
            float  _Roughness;
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

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha  = roughness * roughness;
                float alpha2 = alpha * alpha;
                float NdotH2 = NdotH * NdotH;
                float denom  = NdotH2 * (alpha2 - 1.0) + 1.0;
                return alpha2 / (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha = roughness * roughness;
                float k     = alpha / 2.0;
                return NdotV / (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(float NdotL, float NdotV, float roughness)
            {
                return GeometrySchlickGGX(NdotL, roughness)
                     * GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float NdotV = max(0.0, dot(N, V));
                float NdotH = max(0.0, dot(N, H));
                float VdotH = max(0.0, dot(V, H));

                // Fresnel geometrico para transparencia
                float fresnelAlpha = pow(1.0 - abs(dot(N, V)), _FresnelPower);
                float alpha        = saturate(_Opacity + fresnelAlpha * 0.65);

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse  = _AlbedoColor.rgb;

                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GeometrySmith(NdotL, NdotV, _Roughness);

                float3 specular = (F * D * G) / (4.0 * NdotL * NdotV + 0.001);

                float3 color = ambient
                             + _LightIntensity.rgb * (diffuse + specular) * NdotL;

                color *= _GlassColor.rgb;

                return fixed4(color, alpha * 0.6);
            }
            ENDCG
        }*/

        // =============================================
        // PASS 2: Front faces
        // =============================================
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
            float4 _AlbedoColor;
            float4 _F0;
            float  _Roughness;
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

            float3 FresnelSchlick(float3 F0, float VdotH)
            {
                return F0 + (1.0 - F0) * pow(1.0 - VdotH, 5.0);
            }

            float DistributionGGX(float NdotH, float roughness)
            {
                float alpha  = roughness * roughness;
                float alpha2 = alpha * alpha;
                float NdotH2 = NdotH * NdotH;
                float denom  = NdotH2 * (alpha2 - 1.0) + 1.0;
                return alpha2 / (UNITY_PI * denom * denom);
            }

            float GeometrySchlickGGX(float NdotV, float roughness)
            {
                float alpha = roughness * roughness;
                float k     = alpha / 2.0;
                return NdotV / (NdotV * (1.0 - k) + k);
            }

            float GeometrySmith(float NdotL, float NdotV, float roughness)
            {
                return GeometrySchlickGGX(NdotL, roughness)
                     * GeometrySchlickGGX(NdotV, roughness);
            }

            fixed4 fragmentShader(v2f f) : SV_Target
            {
                float3 N = normalize(f.normal_w);
                float3 L = normalize(_LightPosition_w.xyz - f.position_w.xyz);
                float3 V = normalize(_WorldSpaceCameraPos - f.position_w.xyz);
                float3 H = normalize(L + V);

                float NdotL = max(0.0, dot(N, L));
                float NdotV = max(0.0, dot(N, V));
                float NdotH = max(0.0, dot(N, H));
                float VdotH = max(0.0, dot(V, H));

                float fresnelAlpha = pow(1.0 - abs(dot(N, V)), _FresnelPower);
                float alpha        = saturate(_Opacity + fresnelAlpha * 0.65);

                float3 ambient  = _AmbientLight.rgb * _MaterialKa.rgb;
                float3 diffuse  = _AlbedoColor.rgb;

                float3 F = FresnelSchlick(_F0.rgb, VdotH);
                float  D = DistributionGGX(NdotH, _Roughness);
                float  G = GeometrySmith(NdotL, NdotV, _Roughness);

                float3 specular = (F * D * G) / (4.0 * NdotL * NdotV + 0.001);

                float3 color = ambient
                             + _LightIntensity.rgb * (diffuse + specular) * NdotL;

                color *= _GlassColor.rgb;

                return fixed4(color, alpha);
            }
            ENDCG
        }
    }
}
