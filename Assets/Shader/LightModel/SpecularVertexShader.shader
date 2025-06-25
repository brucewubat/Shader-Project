Shader "Custom/LightModel/SpecularVertexShader"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
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
                float4 _Specular;
                float _Gloss;
            CBUFFER_END

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                //逐顶点 实现镜面反射 计算部分在 顶点着色器中
                v2f o;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                //环境光
                float3 ambient = unity_AmbientSky.rgb;
                //法线
                float3 worldNormal = TransformObjectToWorldNormal(v.normal);
                // 获取光照方向
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                // 漫反射
                float3 diffuse = mainLight.color*_Diffuse.rgb*saturate(dot(worldNormal,lightDir));
                
                //反射方向
                float3 reflectDir = normalize(reflect(-lightDir,worldNormal));
                //视角方向
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz-mul(unity_ObjectToWorld,v.vertex).xyz);
                //镜面反射
                float3 specular = mainLight.color*_Specular.rgb*pow(saturate(dot(reflectDir,viewDir)),_Gloss);
                o.color =ambient+ diffuse + specular; 
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                return half4 (i.color,1.0);
            }
            
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
