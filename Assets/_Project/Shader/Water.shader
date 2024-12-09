Shader "Custom/Water"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Caustics ("Caustics", 2D) = "white" {}

        _Frequency ("Frequency", Vector) = (1,1,0,0)
        _Amplitude ("Amplitude", Vector) = (1,1,0,0)
        _Speed ("Speed", Vector) = (1,1,0,0)
        _ScrollSpeed ("Scroll Speed", Vector) = (1,1,0,0)
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
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            TEXTURE2D(_NormalMap);
            SAMPLER(sampler_NormalMap);

            TEXTURE2D(_Caustics);
            SAMPLER(sampler_Caustics);

            float4 _Color;

            float4 _Frequency;
            float4 _Amplitude;
            float4 _Speed;

            float4 _ScrollSpeed;

            v2f vert(appdata IN)
            {
                // calculate wave displacement
                float waveX = sin(_Time.y * _Speed.x + IN.vertex.x * _Frequency.x) * _Amplitude.x;
                float3 displaced = IN.vertex.xyz;
                float waveY = sin(_Time.y * _Speed.y + IN.vertex.z * _Frequency.y) * _Amplitude.y;
                displaced.y += waveX + waveY;
                
                v2f OUT;
                OUT.vertex = TransformObjectToHClip(displaced);
                OUT.uv = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            float4 frag(v2f IN) : SV_Target
            {
                // calculate scrolling UV
                float2 scrolledUV = IN.uv + float2(_ScrollSpeed.x, _ScrollSpeed.y) * _Time.y;
                float2 scrolledFoamUV = IN.uv + float2(_ScrollSpeed.x/2, _ScrollSpeed.y/2) * _Time.y;
                float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, scrolledUV);
                float4 foam = SAMPLE_TEXTURE2D(_Caustics, sampler_Caustics, scrolledFoamUV);
                return (color + foam)/2;
            }
            ENDHLSL
        }

    }
    FallBack "Diffuse"
}