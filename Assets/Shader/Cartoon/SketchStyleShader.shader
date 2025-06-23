Shader "Custom/Cartoon/SketchStyleShader"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D) = "white" {}
		_Hatch1 ("Hatch 1", 2D) = "white" {}
		_Hatch2 ("Hatch 2", 2D) = "white" {}
		_Hatch3 ("Hatch 3", 2D) = "white" {}
		_Hatch4 ("Hatch 4", 2D) = "white" {}
		_Hatch5 ("Hatch 5", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalRenderPipeline" "RenderType"="Opaque" "Queue"="Geometry"  }
        LOD 100

        UsePass "Custom/Cartoon/CartoonStyleShader/OUTLINE"
        
        Pass
        {
        	NAME "SKETCH"
            Tags { "LightMode"="UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            
            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _TileFactor;
            CBUFFER_END
            
            TEXTURE2D(_Hatch0);
            SAMPLER(sampler_Hatch0);
            TEXTURE2D(_Hatch1);
            SAMPLER(sampler_Hatch1);
            TEXTURE2D(_Hatch2);
            SAMPLER(sampler_Hatch2);
            TEXTURE2D(_Hatch3);
            SAMPLER(sampler_Hatch3);
            TEXTURE2D(_Hatch4);
            SAMPLER(sampler_Hatch4);
            TEXTURE2D(_Hatch5);
            SAMPLER(sampler_Hatch5);

            struct a2v {
				float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 hatchWeights0 : TEXCOORD1;
				float3 hatchWeights1 : TEXCOORD2;
				float3 worldPos : TEXCOORD3;
				float4 shadowCoord : TEXCOORD4; // 阴影坐标
			};

            v2f vert(a2v v)
            {
            	
	            v2f o;
            	o.pos = TransformObjectToHClip(v.vertex.xyz);
            	o.uv = v.texcoord.xy * _TileFactor;
            	o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
            	o.shadowCoord = TransformWorldToShadowCoord(TransformObjectToWorld(v.vertex.xyz));

            	Light mainLight = GetMainLight();
                float3 lightDir = mainLight.direction; // 世界空间光源方向
            	if (mainLight.distanceAttenuation != 1.0)
            	{
                    lightDir = normalize(mainLight.direction - o.worldPos);
                }
            	float3 worldNormal = TransformObjectToWorldNormal(v.normal); 
            	float diff = max(0, dot(lightDir, worldNormal));

            	o.hatchWeights0 = float3(0,0,0);
            	o.hatchWeights1 = float3(0,0,0);

            	float hatchFactor = diff * 7.0;

            	if (hatchFactor > 6.0) {
					// Pure white, do nothing
				} else if (hatchFactor > 5.0) {
					o.hatchWeights0.x = hatchFactor - 5.0;
				} else if (hatchFactor > 4.0) {
					o.hatchWeights0.x = hatchFactor - 4.0;
					o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
				} else if (hatchFactor > 3.0) {
					o.hatchWeights0.y = hatchFactor - 3.0;
					o.hatchWeights0.z = 1.0 - o.hatchWeights0.y;
				} else if (hatchFactor > 2.0) {
					o.hatchWeights0.z = hatchFactor - 2.0;
					o.hatchWeights1.x = 1.0 - o.hatchWeights0.z;
				} else if (hatchFactor > 1.0) {
					o.hatchWeights1.x = hatchFactor - 1.0;
					o.hatchWeights1.y = 1.0 - o.hatchWeights1.x;
				} else {
					o.hatchWeights1.y = hatchFactor;
					o.hatchWeights1.z = 1.0 - o.hatchWeights1.y;
				}
            	
            	return o;
            	
            }

            float4 frag(v2f i): SV_Target
            {
            	
	            float4 hatchTex0 = SAMPLE_TEXTURE2D(_Hatch0, sampler_Hatch0, i.uv) * i.hatchWeights0.x;
				float4 hatchTex1 = SAMPLE_TEXTURE2D(_Hatch1, sampler_Hatch1, i.uv) * i.hatchWeights0.y;
				float4 hatchTex2 = SAMPLE_TEXTURE2D(_Hatch2, sampler_Hatch2, i.uv) * i.hatchWeights0.z;
				float4 hatchTex3 = SAMPLE_TEXTURE2D(_Hatch3, sampler_Hatch3, i.uv) * i.hatchWeights1.x;
				float4 hatchTex4 = SAMPLE_TEXTURE2D(_Hatch4, sampler_Hatch4, i.uv) * i.hatchWeights1.y;
				float4 hatchTex5 = SAMPLE_TEXTURE2D(_Hatch5, sampler_Hatch5, i.uv) * i.hatchWeights1.z;
				float4 whiteColor = float4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - 
							i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
				
				float4 hatchColor = hatchTex0 + hatchTex1 + hatchTex2 + hatchTex3 + hatchTex4 + hatchTex5 + whiteColor;
				return float4(hatchColor.rgb * _Color.rgb , 1.0);
				
            }
            
            ENDHLSL
        }
    }
	//FallBack "Universal Render Pipeline/Diffuse"
}
