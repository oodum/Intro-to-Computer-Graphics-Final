Shader "Custom/Hologram"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Range(0.0, 0.03)) = 0.01
        _Shininess("Shininess", Range(0,1)) = 0.4
        _SpecularColor("Specular Color", Color) = (0.5,0.5,0.5,1)
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
                float3 viewDirection : TEXCOORD2;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float4 _OutlineColor;
            float _OutlineWidth;

            float _Shininess;
            float4 _SpecularColor;

            v2f vert(appdata IN)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                o.vertex = TransformObjectToHClip(IN.vertex);
                o.normal = normalize(TransformObjectToWorldNormal(IN.normal));
                // Calculate the view direction in world space
                float3 worldPosition = TransformObjectToWorld(IN.vertex.xyz);
                o.viewDirection = GetCameraPositionWS() - worldPosition;
                return o;
            }

            float4 frag(v2f IN) : SV_Target
            {
                // Sample the texture
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                // Store struct properties as variables in the local scope
                float3 normal = normalize(IN.normal);
                float3 viewDirection = normalize(IN.viewDirection);

                // Get light information
                Light light = GetMainLight();
                float3 lightDirection = light.direction;

                // Diffuse/NdotL
                float NdotL = saturate(dot(IN.normal, lightDirection));
                float3 diffuse = NdotL * light.color * color;

                // Ambient
                float3 ambient = SampleSH(normal), _Opacity;

                // Specular
                float3 reflectDirection = reflect(-lightDirection, normal);
                // Blinn-Phong
                float specularFactor = pow(saturate(dot(reflectDirection, viewDirection)), _Shininess);
                float3 specular = specularFactor * _SpecularColor * light.color;

                return float4(diffuse + ambient + specular + color, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}