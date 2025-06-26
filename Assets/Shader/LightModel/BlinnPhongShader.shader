Shader "Custom/LightModel/BlinnPhongShader"
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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                o.worldNormal = TransformObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                //blinn-phong 半程向量
                //环境光
                float3 ambient = unity_AmbientSky.rgb;
                //法线
                float3 worldNormal = normalize(i.worldNormal);
                // 获取光照方向
                Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction;
                
                // 漫反射
                float3 diffuse = mainLight.color*_Diffuse.rgb*saturate(dot(worldNormal,lightDir));
                //视角方向
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos);
                //半程向量
                float3 halfDir = normalize(lightDir+viewDir);
                
                //镜面反射
                float3 specular = mainLight.color*_Specular.rgb*pow(saturate(dot(worldNormal,halfDir)),_Gloss);
                
                return half4 (ambient+ diffuse + specular,1.0);
            }
            
            ENDHLSL
        }
    }
    Fallback "Diffuse"
}
