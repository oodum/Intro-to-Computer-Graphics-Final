# Intro to Computer Graphics Final
Adam Tam - 100868600
Odd number -> Super Mario World

# Shader 1 -> Hologram
This is a modified version of the hologram we learned in class. The most important
part about this shader is the fact that opacity is applied manually to all components except for the rim.
This is because I want everything that isn't the rim to be affected by the opacity, but the
rim must be solid so that the outline persists and the effect is not lost.

Of course, with opacity, that means I need to use the Blend SrcAlpha OneMinusSrcAlpha, as well as the correct
tags for the pass. This is because the shader is transparent and must be rendered in the correct order.

I used this shader for Mario's hit animation, where he uses this shader to show he is hit.
```csharp
Shader "Custom/Hologram"
{
    Properties
    {
        _HologramColor("HologramColor", Color) = (1,1,1,1)
        _HologramStrength("HologramStrength", Range(0,1)) = 0.5
        _Opacity("Opacity", Range(0,1)) = 0.5
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimPower("Rim Power", Range(0,8)) = 3
        _SpecularColor("Specular Color", Color) = (0.5,0.5,0.5,1)
        _Shininess("Shininess", Range(0,1)) = 0.4
    }
    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
        }
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

            float4 _HologramColor;
            float _HologramStrength;

            float _Opacity;
            float4 _RimColor;
            float _RimPower;

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
                float4 diffuse = float4(NdotL * light.color * color , _Opacity);

                // Ambient
                float4 ambient = float4(SampleSH(normal), _Opacity);

                // Specular
                float3 reflectDirection = reflect(-lightDirection, normal);
                // Blinn-Phong
                float specularFactor = pow(saturate(dot(reflectDirection, viewDirection)), _Shininess);
                float4 specular = float4(specularFactor * _SpecularColor * light.color, _Opacity);

                // Calculate rim lighting
                float rimFactor = 1 - saturate(dot(normal, viewDirection));
                float4 rimColor = _RimColor * pow(rimFactor, _RimPower);

                // Hologram effect
                color = float4(lerp(color, _HologramColor, _HologramStrength).xyz, _Opacity);

                return diffuse + ambient + specular + rimColor + color;
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
```

# Shader 2 -> Water
This is a modified version of the water shader we learned in class.
I changed it so that all the "moving parts", such as the amplitude, speed, and frequency, are all
vectors (float4) instead of floats. This allows me to affect the x and y components within a variable instead
of splitting them up and creating data clumps.

I used caustics as well, which is a texture that is overlaid on top of the water texture. The caustics
scroll in the same direction as the main texture, but at half the speed. This is to create a more realistic
effect of light shining through the water and creating patterns on the ground.
```csharp
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
```

# Shader 3 -> Mario
This is the basic shader for mario. It uses diffuse, ambient, and specular lighting. I attempted to use
the outline but it did not work properly
```csharp
Shader "Custom/Hologram"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _OutlineWidth("Outline Width", Range(0.0, 1)) = 0.01
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

                // Outline
                float4 outlineColor = _OutlineColor * step(_OutlineWidth, fwidth(NdotL));

                return float4(diffuse + ambient + specular + color + outlineColor, 1);
            }
            ENDHLSL
        }
    }
    FallBack "Diffuse"
}
```

# Shader 4 -> Basic Ground Shader
Unfortunately, I did not have time to implement a more complex shader for the enemies, so I had to use this basic shader instead.
This shader is a simple shader that 

# Color Correction
I used Unity's Post Processing effects to color-grade the scene. This is all visible inside the scene's Global Volume.

Note that Vignette and Bloom are being used, but they are default settings and I did not change them.

Firstly, I applied an ACES tonemapper to get my preferred color space

Then, I applied color adjustments to wash out the color. I did this to replicate a more retro style

Finally, I applied some grain to the scene to give it a more retro feel