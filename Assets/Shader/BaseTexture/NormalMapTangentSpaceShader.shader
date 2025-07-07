Shader "Custom/BaseTexture/NormalMapTangentSpaceShader"
{
    Properties
    {
        _Color("Color Tint",Color) = (1,1,1,1)
        _MainTex ("Texture", 2D) = "white" {}
        _BumpMap("Normal Map",2D) = "bump" {}
        _BumpScale ("Bump Scale", Float) = 1.0
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
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
                float4 _Color;
                float4 _Specular;
                float _BumpScale;
                float _Gloss;
            CBUFFER_END

            float4 _MainTex_ST;
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            float4 _BumpMap_ST;
            TEXTURE2D(_BumpMap);
            SAMPLER(sampler_BumpMap);
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 position : SV_POSITION;
                float4 uv : TEXCOORD0;
                float3 lightDir : TEXCOORD1;
                float3 viewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                //两组纹理坐标 分别对应mainTex和bumpMap
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);
                
                //切线空间下 计算副法线 binormal
                float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz))*v.tangent.w;
                //构造从object space转换到tangent space的变换矩阵 此处 按列
                float3x3 ObjToTangent = float3x3(v.tangent.xyz,binormal,v.normal);
                //世界空间的光照方向
                float3 worldLightDir = GetMainLight().direction;  

                // 向量变换
                float3x3 worldToObjectMatrix = (float3x3)unity_WorldToObject;
                
                //光照方向
                float3 objectSpaceLightDir = mul(worldLightDir, worldToObjectMatrix);
                o.lightDir = mul(ObjToTangent,objectSpaceLightDir);
                //视角方向
                float3 worldViewDir = _WorldSpaceCameraPos-v.vertex.xyz;
                float3 objectSpaceViewDir = mul(worldViewDir,worldToObjectMatrix);
                o.viewDir = mul(ObjToTangent,objectSpaceViewDir);
                
                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                float3 tangentLightDir = normalize(i.lightDir);
                float3 tangentViewDir = normalize(i.viewDir);

                float4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap, i.uv.zw);
                float3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                
                //环境光
                float3 ambient = unity_AmbientSky.rgb;
                
                // 获取光照
                Light mainLight = GetMainLight();
                //反射率
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb * _Color.rgb;
                
                // 漫反射
                float3 diffuse = mainLight.color*albedo.rgb*saturate(dot(tangentNormal,tangentLightDir));
                
                //半程向量
                float3 halfDir = normalize(tangentLightDir+tangentViewDir);
                
                //镜面反射
                float3 specular = mainLight.color*_Specular.rgb*pow(saturate(dot(tangentNormal,halfDir)),_Gloss);
                
                return half4 (ambient+ diffuse + specular,1.0);
            }
            
            ENDHLSL
        }
    }
    Fallback Off
}
