Shader "GeoTetra/GTAvaToon/Outline/GTToonMatcap"
{	
	Properties
    {
    	[GTFoldoutHeader(Base)]
    	
    	[Header(Diffuse)]
	    [GTPropertyDrawer(Diffuse color.)]
	    _Color ("Diffuse Color", Color) = (1, 1, 1, 1)
    	
    	[GTPropertyDrawer(Multiply Diffuse Color by texture.)]
        _MainTex ("Diffuse Texture", 2D) = "white" {}
	    
    	
        [GTFoldoutHeader(Outline)]
    	
        [Header(Outline Color)]
    	[GTPropertyDrawer(RGB color and alpha of outline.)]
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
    	
    	[GTPropertyDrawer(Multiply Outline Color by RGB color and alpha from texture.)]
	    _OutlineColorTex ("Outline Color Texture", 2D) = "white" {}

        [Header(Outline Size)]
    	[GTPropertyDrawer(Primary line size. Change this to control overall line thickness.)]
    	_LineSize ("Line Size", Range(0, 2)) = .8
    	
    	[GTPropertyDrawer(Line size when your view is zero distance from the surface. Change this to make the line thinner when up close.)]
        _LineSizeNear ("Line Size Near", Range(0, 2)) = .2
    	
    	[GTPropertyDrawer(The distance at which the line size will transition from Line Size Near to Line Size.)]
        _NearLineSizeRange ("Near Line Size Range", Range(0, 4)) = 1

    	[GTFoldoutHeader(Depth Outline)]
    	
        [Header(Depth Map)]
    	[GTPropertyDrawer(Set to be the total extents of the avatar. Should be same for all materials on avatar.)]
        _BoundingExtents ("Depth Bounding Extents", Float) = .5
    	
    	[GTPropertyDrawer(Will offset the materials depth value. This can be used to force lines to be drawn between materials.)]
        _DepthOffset ("Depth Bounding Offset", Range(-.5,.5)) = 0
    	
    	[GTPropertyDrawer(Lower value will capture more detail from the depth but the lines will be more aliased and grainy. As you adjust pay attention to AA quality of the line in game view.)]
        _LocalEqualizeThreshold ("Depth Local Adaptive Equalization Threshold", Range(0.01, .1)) = .03
    	
	    [ToggleUI] 
    	[GTPropertyDrawer(Draw the sillhouette around the avatar at a distance. Recommend to leave on as it helps minimize subtle artifacts at a distance.)]
    	_DepthSilhouetteMultiplier ("Far Depth Silhouette", Float) = 1

    	
        [Header(Depth Outline Gradient)]
    	
    	[GTPropertyDrawer(Depth threshold to start drawing line. Lower value will make more detail but may also show artifacting.)]
        _DepthGradientMin ("Depth Outline Gradient Min", Range(0, 1)) = .05
    	
    	[GTPropertyDrawer(Depth threshold by which the line will fade out. Lower value will make more detail but will cause lines to be more aliased and grainy.)]
        _DepthGradientMax ("Depth Outline Gradient Max", Range(0, 1)) = 0.4
    	
    	[GTPropertyDrawer(Utilize fwidth to apply additinal softness to line. Larger values will make it softer but will reveal block artifacts.)]
        _DepthEdgeSoftness ("Depth Outline Edge Softness", Range(0, 2)) = .25
    	
    	
    	[GTFoldoutHeader(Normal Outline)]
    	
        [Header(Concave Normal Outline Sampling)]
        _NormalSampleMult ("Concave Outline Sampling Multiplier", Range(0,10)) = 1
        _FarNormalSampleMult ("Far Concave Outline Multiplier", Range(0,10)) = 10

        [Header(Convex Normal Outline Sampling)]
        _ConvexSampleMult ("Convex Outline Sampling Multiplier", Range(0,10)) = 0
        _FarConvexSampleMult ("Far Convex Outline Multiplier", Range(0,10)) = 0

        [Header(Normal Outline Gradient)]
        _NormalGradientMin ("Normal Gradient Min", Range(0, 1)) = 0
        _NormalGradientMax ("Normal Gradient Max", Range(0, 1)) = .2
        _NormalEdgeSoftness ("Normal Edge Softness", Range(0, 2)) = .25
        
    	[Header(Normal Far Distance)]
        _FarDist ("Normal Far Distance", Range(0,10)) = 10
    	
        [GTFoldoutHeader(Local Lighting)]
    	
    	[Header(Add Lighting)]
        _LightingColor ("Add Lighting Color", Color) = (0,0,0,1)
    	_LightingColorTex ("Add Lighting Texture", 2D) = "white" {}

        [Header(MatCap)]
        _MatCapTex ("MatCap", 2D) = "black" {}
        _MatCapMult ("MatCap Multiply", Range(0,6)) = .5
        _MatCapAdd ("MatCap Add", Range(0,6)) = .02
        _MatCapInset ("MatCap Inset", Range(0,1)) = .1
    	
    	[Header(AO Vertex Color)]
        _VertexColorBlend ("AO Vertex Color Alpha", Range(0,2)) = 0

        [Header(Rim Add)]
        _RimAddMult ("Rim Multiplier", Range(0,2)) = .8
        _RimAddBias ("Rim Bias", Range(0,20)) = 10
        _RimAddColor ("Rim Add Color", Color) = (1, 1, 1, 1)
        _RimAddColorBlend ("Rim Add Final Color Blend", Range(0,1)) = .2

    	[Header(Rim Darken)]
        _RimMultiplyGradientMin ("Rim Darken Gradient Min", Range(.95,1.05)) = .995
        _RimMultiplyGradientMax ("Rim Darken Gradient Max", Range(.95,1.05)) = 1
    	_RimMultiplyEdgeSoftness ("Rim Darken Edge Softness", Range(0,2)) = .5
            	
    	[GTFoldoutHeader(World Lighting)]
        
        [Header(Light Levels)]
        _DirectBlackLevel ("Black Level", Range(0,1)) = 0
        _DirectWhiteLevel ("White Level", Range(0,1)) = .8
        _DirectOutputBlackLevel ("Output Black Level", Range(0,1)) = .2
        _DirectOutputWhiteLevel ("Output White Level", Range(0,1)) = 1
        _DirectGamma ("Gamma", Range(0,2)) = .5        
    	
    	[Header(Light Probes)]
    	_ProbeAverage ("Probe Average", Range(1,100)) = 1
    }	
			
	CustomEditor "GeoTetra.GTAvaToon.Editor.GTToonMatcapGUI"
	
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
                const float2 screenUv  = i.scrPos.xy / i.scrPos.w;
            	
                float4 sample = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)) * _Color;
                float3 diffuse = sample.xyz;

            	UNITY_LIGHT_ATTENUATION(attenuation, i, normalizedWorldSpaceNormal);
            	applyLighting(diffuse, i.uv0, attenuation, normalizedWorldSpaceNormal, i.worldPosition, i.color);
                applyToonOutline(diffuse, screenUv, i.uv0, i.pos.w);
                
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