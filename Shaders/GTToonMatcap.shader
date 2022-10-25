Shader "GeoTetra/GTAvaToon/Outline/GTToonMatcap"
{
    Properties
    {
        [Header(Base)]
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex ("Main Texture", 2D) = "white" {}
        _AddTex ("Add Texture", 2D) = "white" {}
        
        [Header(### Outline)]

        [Header(Outline Color)]
        _OutlineColor ("Outline Color", Color) = (0,0,0,0)
        _OutlineColorTex ("Outline Color Texture", Color) = (0,0,0,0)

        [Header(Outline Size)]
        _LineSizeNear ("Line Size Near", Range(0, 2)) = .2
        _LineSize ("Line Size", Range(0, 2)) = .8
        _NearLineSizeRange ("Near Line Size Range", Range(0, 4)) = 1

        [Header(Depth Map)]
        _BoundingExtents ("Depth Bounding Extents", Float) = .5
        _DepthOffset ("Depth Bounding Offset", Range(-.5,.5)) = 0
    	_DepthOffsetTex ("Depth Offset Texture", Color) = (0,0,0,0)
        _LocalEqualizeThreshold ("Depth Local Adaptive Equalization Threshold", Range(0.01, .1)) = .02
        [ToggleUI] _DepthSilhouetteMultiplier ("Depth Silhouette", Float) = 1

        [Header(Depth Outline Gradient)]
        _DepthGradientMin ("Depth Outline Gradient Min", Range(0, 1)) = 0
        _DepthGradientMax ("Depth Outline Gradient Max", Range(0, 1)) = 0.5
        _DepthEdgeSoftness ("Depth Outline Edge Softness", Range(0, 2)) = .25

        [Header(Concave Normal Outline Sampling)]
        _NormalSampleMult ("Concave Outline Sampling Multiplier", Range(0,10)) = 1
        _FarNormalSampleMult ("Far Concave Outline Multiplier", Range(0,10)) = 10

        [Header(Convex Normal Outline Sampling)]
        _ConvexSampleMult ("Convex Outline Sampling Multiplier", Range(0,10)) = 0
        _FarConvexSampleMult ("Far Convex Outline Multiplier", Range(0,10)) = 0

        [Header(Normal Outline Gradient)]
        _NormalGradientMin ("Normal Gradient Min", Range(0, 1)) = 0
        _NormalGradientMax ("Normal Gradient Max", Range(0, 1)) = .3
        _NormalEdgeSoftness ("Normal Edge Softness", Range(0, 2)) = .25

        [Header(Far)]
        _FarDist ("Far Distance", Range(0,10)) = 10

        [Header(### Shading)]

        [Header(MatCap)]
        _MatCap ("MatCap", 2D) = "white" {}
        _MatCapMult ("MatCap Multiply", Range(0,6)) = .5
        _MatCapAdd ("MatCap Add", Range(0,6)) = .02
        _MatCapInset ("MatCap Inset", Range(0,1)) = .1

        [Header(Rim Add)]
        _RimAddMult ("Rim Multiplier", Range(0,2)) = .8
        _RimAddBias ("Rim Bias", Range(0,20)) = 10
        _RimAddColor ("Rim Add Color", Color) = (1, 1, 1, 1)
        _RimAddColorBlend ("Rim Add Final Color Blend", Range(0,1)) = .2

    	[Header(Rim Darken)]
        _RimMultiplyGradientMin ("Rim Darken Gradient Min", Range(.95,1.05)) = .995
        _RimMultiplyGradientMax ("Rim Darken Gradient Max", Range(.95,1.05)) = 1
    	_RimMultiplyEdgeSoftness ("Rim Darken Edge Softness", Range(0,2)) = .5

        [Header(Vertex Color)]
        _VertexColorBlend ("Vertex Color Blend", Range(0,2)) = 0
        _VertexColorBias ("Vertex Color Bias", Range(0,2)) = 1

        [Header(### Lighting)]
        
        [Header(Direct Light Levels)]
        _DirectBlackLevel ("DirectBlackLevel", Range(0,1)) = 0
        _DirectWhiteLevel ("DirectWhiteLevel", Range(0,1)) = .8
        _DirectOutputBlackLevel ("DirectOutputBlackLevel", Range(0,1)) = .2
        _DirectOutputWhiteLevel ("DirectOutputWhiteLevel", Range(0,1)) = 1
        _DirectGamma ("DirectGamma", Range(0,2)) = .5        
    	
    	[Header(Light Probes)]
    	_ProbeAverage ("Probe Average", Range(1,100)) = 1
    }
    Subshader
    {
        Tags
        {
            "Queue" = "Geometry+10" "RenderType" = "Opaque"
        }

        Pass
        {        	
	        HLSLPROGRAM
	        #pragma target 5.0
            #pragma vertex grabpass_vert
            #pragma fragment grabpass_frag
	        #include "GTToonOutlineGrabPass.hlsl"
            ENDHLSL
        }

        GrabPass
        {
            "_GTToonGrabTexture"
        }

        Pass
        {
        	Tags
            {
                "LightMode" = "ForwardBase"
            }
        	
	        HLSLPROGRAM	        
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
	        #pragma multi_compile_fwdbase
	        #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED

	        #include "UnityCG.cginc"
	        #include "AutoLight.cginc"
	        #include "GTToonOutline.hlsl"
	        #include "GTLit.hlsl"

            struct appdata
            {
                float4 vertex : POSITION0;
                float3 normal : NORMAL0;
            	float4 tangent : TANGENT0;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR0;

	        	UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : POSITION0;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR0;
            	float3 worldPosition : POSITION1;
            	centroid float3 worldNormal : NORMAL0;
            	float4 scrPos : POSITION2;

            	UNITY_SHADOW_COORDS(7)
            	
                UNITY_VERTEX_OUTPUT_STEREO
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
            float4 _Color;
	                    
            v2f vert(const appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
            	
                o.pos = UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);
            	
                o.uv0 = v.uv0;
            	o.uv1 = v.uv1;
            	
                o.color = v.color;
            	
				o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

            	UNITY_TRANSFER_LIGHTING(o, v.uv1);
            	
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
            	const float3 normalizedWorldSpaceNormal = normalize(i.worldNormal);
                const float2 centerUV  = i.scrPos.xy / i.scrPos.w;

                float4 sample = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)) * _Color;
                float3 diffuse = sample.xyz;
            	
            	applyVertexColors(diffuse, i.color, sample.a);
            	
                applyLocalLighting(diffuse, normalizedWorldSpaceNormal, i.worldPosition);
                UNITY_LIGHT_ATTENUATION(attenuation, i, normalizedWorldSpaceNormal);
                applyWorldLighting(diffuse, normalizedWorldSpaceNormal, attenuation);
            	
                applyToonOutline(diffuse, centerUV, i.pos.w, sample.a);
                
                return float4(diffuse, 1);
            }
            ENDHLSL
        }

        Pass {
            Tags {"LightMode" = "ShadowCaster"}
            HLSLPROGRAM
            #pragma vertex shaddow_vert
            #pragma fragment shadow_frag
            #pragma multi_compile_shadowcaster
            #include "GTShadow.hlsl"
            ENDHLSL
        }
    }
}