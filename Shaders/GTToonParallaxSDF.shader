Shader "GeoTetra/Expirimental/GTToonParallaxSDF"
{
    Properties
    {
        [Header(##### Expirimental and Funky. Do Not Use. #####)]
        
        [Header(Base)]
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _MainTex (" Main Texture", 2D) = "white" {}

        [Header(SDF)]
        _SDFColor0 ("_SDFColor0", Color) = (1, 1, 1, 1)
        _SDF0 ("_SDF0", 2D) = "white" {}
        _SDF0Threshold ("_SDF0Threshold", Range(0,1)) = 0.5

        _SDFColor1 ("_SDFColor1", Color) = (1, 1, 1, 1)
        _SDF1 ("_SDF1", 2D) = "white" {}
        _SDF1Threshold ("_SDF1Threshold", Range(0,1)) = 0.5

        _SDFColor2 ("_SDFColor2", Color) = (1, 1, 1, 1)
        _SDF2 ("_SDF2", 2D) = "white" {}
        _SDF2Threshold ("_SDF2Threshold", Range(0,1)) = 0.5

        [Header(Parrallax)]
        _ParallaxHeight ("_ParallaxHeight", Float) = 1

        [Header(### Outline)]

        [Header(Outline Color)]
        _OutlineColor ("Outline Color", Color) = (0,0,0,1)
        _OutlineColorTex ("Outline Color Texture", 2D) = "white" {}

        [Header(Outline Size)]
        _LineSizeNear ("Line Size Near", Range(0, 2)) = .2
        _LineSize ("Line Size", Range(0, 2)) = .8
        _NearLineSizeRange ("Near Line Size Range", Range(0, 4)) = 1

        [Header(Depth Map)]
        _BoundingExtents ("Depth Bounding Extents", Float) = .5
        //    	_DepthOffsetTex ("Depth Offset Texture", Color) = (0,0,0,0)
        _LocalEqualizeThreshold ("Depth Local Adaptive Equalization Threshold", Range(0.01, .1)) = .03
        _DepthId ("Depth Id", Range(0,1)) = 0

        [Header(Depth Outline Gradient)]
        _DepthGradientMin ("Depth Outline Gradient Min", Range(0, 1)) = 0.05
        _DepthGradientMax ("Depth Outline Gradient Max", Range(0, 1)) = 0.4
        
        [Header(Normal Outline Gradient)]
        
        [Header(Concave Normal Outline)]
    	
    	[Tooltip(Depth threshold to start drawing line from normal concavity. Lower value will make more detail.)]
        _NormalGradientMin ("Concave Normal Outline Gradient Min", Range(0, 1)) = 0
    	
    	[Tooltip(Depth threshold by which the line will fade out from normal concavity. Lower value will make more detail but will cause lines to be more aliased and grainy.)]
        _NormalGradientMax ("Concave Normal Outline Gradient Max", Range(0, 1)) = .4
        
        [Header(Convex Normal Outline Sampling)]
    	
    	[Tooltip(Depth threshold to start drawing line from normal convexity. Lower value will make more detail.)]
        _ConvexNormalGradientMin ("Convex Normal Outline Gradient Min", Range(0, 1)) = .8
    	
    	[Tooltip(Depth threshold by which the line will fade out from normal convexity. Lower value will make more detail but will cause lines to be more aliased and grainy.)]
        _ConvexNormalGradientMax ("Convex Normal Outline Gradient Max", Range(0, 1)) = 1

        [Header(### Shading)]

        [Header(MatCap)]
        _MatCapTex ("MatCap", 2D) = "white" {}
        _MatCapMult ("MatCap Multiply", Range(0,6)) = .5
        _MatCapAdd ("MatCap Add", Range(0,6)) = .02
        _MatCapInset ("MatCap Inset", Range(0,1)) = .1

        [Header(Rim Add)]
    	_RimAddGradientMin ("Rim Add Gradient Min", Range(.5,1.5)) = .8
        _RimAddGradientMax ("Rim Add Gradient Max", Range(.5,1.5)) = 1.5
        _RimAddColor ("Rim Add Color", Color) = (1, 1, 1, 1)
        _RimAddColorBlend ("Rim Add Final Color Blend", Range(0,1)) = .05

    	[Header(Rim Darken)]
        _RimMultiplyGradientMin ("Rim Darken Gradient Min", Range(.8,1.2)) = .995
        _RimMultiplyGradientMax ("Rim Darken Gradient Max", Range(.8,1.2)) = 1
    	_RimMultiplyEdgeSoftness ("Rim Darken Edge Softness", Range(0,2)) = .5
        
        [Header(### Lighting)]
        _LightingColor ("Add Lighting Color", Color) = (0,0,0,1)
    	_LightingColorTex ("Add Lighting Texture", 2D) = "white" {}
        
        [Header(AO Vertex Color)]
        _VertexColorBlend ("AO Vertex Color Alpha", Range(0,2)) = 0
        _DiscardVertexAOThreshold ("Discard Vertex AO Threshold", Range(0,.1)) = 0
        
        [Header(Direct Light Levels)]
        _DirectBlackLevel ("DirectBlackLevel", Range(0,1)) = 0
        _DirectWhiteLevel ("DirectWhiteLevel", Range(0,1)) = .8
        _DirectOutputBlackLevel ("DirectOutputBlackLevel", Range(0,1)) = .2
        _DirectOutputWhiteLevel ("DirectOutputWhiteLevel", Range(0,1)) = 1
        _DirectGamma ("DirectGamma", Range(0,2)) = .5
        
        [Header(Light Probes)]
    	_ProbeAverage ("Probe Average", Range(50,100)) = 80
    }
    Subshader
    {
        Tags
        {
            "Queue" = "Geometry+10" 
            "RenderType" = "Opaque" 
        }

        Pass
        {
            Tags
	        {
				"IgnoreProjector" = "True"
	        }
            Cull Off
            HLSLPROGRAM
	        #pragma target 5.0
            #pragma vertex grabpass_vert
            #pragma fragment grabpass_frag
	        #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED	        
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
            #include "GTParallax.hlsl"
            
            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR;
                
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 pos : POSITION0;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 scrPos : SCREEN_POSITION; // can get rid of this

                float4 color : COLOR;

                float3 worldPosition : POSITION1;
                centroid float3 worldNormal : NORMAL0;
                centroid float3 worldTangent : NORMAL1;
                centroid float3 worldBinormal : NORMAL2;

                UNITY_SHADOW_COORDS(9)
                
                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            float4 _Color;

            sampler2D _SDF0;
            float4 _SDF0_ST;
            float4 _SDFColor0;
            float _SDF0Threshold;

            sampler2D _SDF1;
            float4 _SDF1_ST;
            float4 _SDFColor1;
            float _SDF1Threshold;

            sampler2D _SDF2;
            float4 _SDF2_ST;
            float4 _SDFColor2;
            float _SDF2Threshold;
            float _ParallaxHeight;
            
            float _DiscardVertexAOThreshold;
            
            v2f vert(const appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = v.color.a < _DiscardVertexAOThreshold ? 0. / 0. : UnityObjectToClipPos(v.vertex);
                o.scrPos = ComputeGrabScreenPos(o.pos);

                o.uv0 = v.uv0;
                o.uv1 = v.uv1;

                o.color = v.color;

                o.worldPosition = mul(unity_ObjectToWorld, v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldTangent = UnityObjectToWorldDir(v.tangent);
                o.worldBinormal = cross(o.worldNormal, o.worldTangent) * (v.tangent.w * unity_WorldTransformParams.w);
                
                UNITY_TRANSFER_LIGHTING(o, v.uv1);

                return o;
            }
            
            float4 frag(v2f i) : SV_Target
            {
                const float3 normalizedWorldSpaceNormal = normalize(i.worldNormal);
                const float2 screenUv = i.scrPos.xy / i.scrPos.w;

                float4 sample = tex2D(_MainTex, i.uv0) * _Color;
                float3 diffuse = sample.xyz;

                // apply sdf colors
                const float sdf0 = tex2D(_SDF0, i.uv0).a;
                const float fd0 = fwidth(sdf0) * 0.75;
                diffuse = lerp(diffuse, _SDFColor0, smoothstep(_SDF0Threshold - fd0, _SDF0Threshold + fd0, sdf0) * _SDFColor0.a);

                const float sdf1 = tex2D(_SDF1, i.uv0).a;
                const float fd1 = fwidth(sdf1) * 0.75;
                diffuse = lerp(diffuse, _SDFColor1, smoothstep(_SDF1Threshold - fd1, _SDF1Threshold + fd1, sdf1) * _SDFColor1.a);

                // apply parallax stuff, expirimental
                float3 tangentViewDir = calcTangentViewDir(i.worldPosition.xyz, i.worldTangent, i.worldBinormal, i.worldNormal);
                layerParallaxes(diffuse, _SDF2, _SDF2Threshold, i.uv1, _SDFColor0, _SDFColor1, _SDFColor2, _ParallaxHeight, tangentViewDir);

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
            #pragma vertex shadow_vert
            #pragma fragment shadow_frag
            #pragma multi_compile_shadowcaster
            #include "VRChatShadow.cginc"
            ENDHLSL
        }
    }
}