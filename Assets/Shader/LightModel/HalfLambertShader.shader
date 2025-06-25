Shader "Custom/LightModel/HalfLambertShader"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "LightMode"="UniversalForward" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _Diffuse;
            CBUFFER_END

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                
                v2f o;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                //法线
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldNormal = worldNormal;
                
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                //逐像素 实现漫反射 计算部分在 片元着色器中
                //环境光
                float3 ambient = unity_AmbientSky.rgb;
                // 获取光照方向
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                
                //计算光照 halfLambert
                float3 diffuse = mainLight.color*_Diffuse.rgb*(dot(i.worldNormal,lightDir)*0.5+0.5);

                float3 color = ambient+diffuse;
                
                return half4 (color,1.0);
            }
            ENDHLSL
        }
    }
    Fallback "Diffuse" 

}
