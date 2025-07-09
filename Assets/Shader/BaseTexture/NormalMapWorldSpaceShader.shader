Shader "Custom/BaseTexture/NormalMapWorldSpaceShader"
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
                float4 TtoW0 : TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.position = TransformObjectToHClip(v.vertex.xyz);
                //两组纹理坐标 分别对应mainTex和bumpMap
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                half3 worldNormal = TransformObjectToWorldNormal(v.normal);
                half3 worldTangent = TransformObjectToWorldDir(v.tangent.xyz);
                half3 worldBinormal = cross(worldNormal,worldTangent)*v.tangent.w;

                o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            half4 frag(v2f i):SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                //世界空间的光照方向
                float3 worldLightDir = GetMainLight().direction;
                //视角方向
                float3 worldViewDir = _WorldSpaceCameraPos-i.position.xyz;

                float4 packedNormal = SAMPLE_TEXTURE2D(_BumpMap,sampler_BumpMap, i.uv.zw);
                float3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                //转换到世界空间下
                tangentNormal = normalize(half3(dot(i.TtoW0.xyz,tangentNormal),
                    dot(i.TtoW1.xyz,tangentNormal),
                    dot(i.TtoW2.xyz,tangentNormal)));
                
                //环境光
                float3 ambient = unity_AmbientSky.rgb;
                
                // 获取光照
                Light mainLight = GetMainLight();
                //反射率
                half3 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv.xy).rgb * _Color.rgb;
                
                // 漫反射
                float3 diffuse = mainLight.color*albedo.rgb*saturate(dot(tangentNormal,worldLightDir));
                
                //半程向量
                float3 halfDir = normalize(worldLightDir+worldViewDir);
                
                //镜面反射
                float3 specular = mainLight.color*_Specular.rgb*pow(saturate(dot(tangentNormal,halfDir)),_Gloss);
                
                return half4 (ambient + diffuse + specular,1.0);
            }
            
            ENDHLSL
        }
    }
    Fallback Off
}
