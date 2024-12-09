Shader "Custom/TileShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : TEXCOORD1;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            v2f vert(appdata IN)
            {
                v2f o;
                // repeat texture, do not scale with the object
                o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                o.vertex = TransformObjectToHClip(IN.vertex);
                o.normal = normalize(TransformObjectToWorldNormal(IN.normal));
                return o;
            }

            float4 frag(v2f IN) : SV_Target
            {
                // sample color
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // calculate diffuse lighting
                Light light = GetMainLight();
                float3 lightDirection = normalize(light.direction);
                float NdotL = saturate(dot(IN.normal, lightDirection));
                float3 diffuse = NdotL * light.color * color;

                // Add base color to diffuse in case light direction is opposite to the normal
                return float4(diffuse + color * 0.6,1);
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}