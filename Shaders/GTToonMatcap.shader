Shader "GeoTetra/GTToonMatcap"
{
    Properties
    {
        [Header(Base)]
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex (" Main Texture", 2D) = "white" {}
        
        [Header(### Outline)]

        [Header(Outline Color)]
        _OutlineColor ("Outline Color", Color) = (0,0,0,0)

        [Header(Outline Size)]
        _LineSizeNear ("Line Size Near", Range(0, 2)) = .1
        _LineSize ("Line Size", Range(0, 2)) = .5
        _NearLineSizeRange ("Near Line Size Range", Range(0, 4)) = .3

        [Header(Depth Map)]
        _BoundingExtents ("Depth Bounding Extents", Float) = .5
        _DepthOffset ("Depth Bounding Offset", Range(-1,1)) = 0

        [Header(Local Adaptive Depth Outline)]
        _LocalEqualizeThreshold ("Depth Local Adaptive Equalization Threshold", Range(0, .1)) = .05
        _DepthMult ("Depth Outline Multiplier", Range(0, 4)) = 1
        _DepthBias ("Depth Outline Bias", Range(0, 10)) = .5
        _FarDepthMult ("Far Depth Outline Multiplier", Range(0, 4)) = .5
        
        [Header(Depth Contrast Outline)]
        _DepthContrastMult ("Depth Contrast Outline Multiplier", Range(0, 2)) = 2
        _FarDepthContrastMult ("Far Depth Contrast Outline Multiplier", Range(0, 2)) = .5

        [Header(Depth Outline Gradient)]
        _DepthGradientMin ("Depth Outline Gradient Min", Range(0, 1)) = 0.05
        _DepthGradientMax ("Depth Outline Gradient Max", Range(0, 1)) = 0.5
        _DepthEdgeSoftness ("Depth Outline Edge Softness", Range(0, 2)) = .25

        [Header(Far Depth Outline)]
        //    	[Tooltip(Distance with Depth Multiplier fades into Far Depth Multiplier)]
        _FarDepthSampleDist ("Far Depth Outline Distance", Range(0,10)) = 3

        [Header(Concave Normal Outline Sampling)]
        _NormalSampleMult ("Concave Outline Sampling Multiplier", Range(0,10)) = 3
        _NormalSampleBias ("Concave Outline Sampling Bias", Range(0,4)) = .5
        _FarNormalSampleMult ("Far Concave Outline Multiplier", Range(0,10)) = 2

        [Header(Convex Normal Outline Sampling)]
        _ConvexSampleMult ("Convex Outline Sampling Multiplier", Range(0,10)) = 1
        _ConvexSampleBias ("Convex Outline Sampling Bias", Range(0,4)) = 1
        _FarConvexSampleMult ("Far Convex Outline Multiplier", Range(0,10)) = .5

        [Header(Normal Outline Gradient)]
        _NormalGradientMin ("Normal Gradient Min", Range(0, 1)) = .1
        _NormalGradientMax ("Normal Gradient Max", Range(0, 1)) = .9
        _NormalEdgeSoftness ("Normal Edge Softness", Range(0, 2)) = .5

        [Header(Far Outline Normal)]
        //    	[Tooltip(Distance with Normal Multiplier fades into Far Normal Multiplier)]
        _FarNormalSampleDist ("Far Normal Outline Distance", Range(0,10)) = 3

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
        _RimMultiplyGradientMin ("Rim Darken Gradient Min", Range(.8,1.2)) = .99
        _RimMultiplyGradientMax ("Rim Darken Gradient Max", Range(.8,1.2)) = 1
    	_RimMultiplyEdgeSoftness ("Rim Darken Edge Softness", Range(0,2)) = .5

        [Header(Vertex Color)]
        _VertexColorBlend ("Vertex Color Blend", Range(0,2)) = 0
        _VertexColorBias ("Vertex Color Bias", Range(0,2)) = 1

        [Header(Lighting)]
        
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
	        #include "GTToonOutlineGrabPass.hlsl"
	        #pragma target 5.0
            #pragma vertex grabpass_vert
            #pragma fragment grabpass_frag
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
	        #include "UnityCG.cginc"
	        #include "AutoLight.cginc"
	        #include "GTToonOutline.hlsl"
	        #include "GTLit.hlsl"
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
	        #pragma multi_compile_fwdbase

            struct appdata
            {
                float4 vertex : POSITION0;
                float3 normal : NORMAL0;
            	float4 tangent : TANGENT0;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR0;
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
            float4 _Color;
	                    
            v2f vert(const appdata v)
            {
                v2f o;
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

                float4 sample = tex2D(_MainTex, i.uv0) * _Color;
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

        // https://docs.unity3d.com/540/Documentation/Manual/SL-VertexFragmentShaderExamples.html
        Pass
        {
            Tags {"LightMode"="ShadowCaster"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_shadowcaster
            #include "UnityCG.cginc"

            struct v2f { 
                V2F_SHADOW_CASTER;
            };

            v2f vert(appdata_base v)
            {
                v2f o;
                TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
                SHADOW_CASTER_FRAGMENT(i)
            }
            ENDCG
        }
    }
}