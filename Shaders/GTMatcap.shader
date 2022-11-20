Shader "GeoTetra/GTAvaToon/IgnoreOutline/GTMatcap"
{	
	Properties
    {
    	[LargeHeader(Base)]
    	
    	[Header(Diffuse)]
	    [Tooltip(Diffuse color.)]
	    _Color ("Diffuse Color", Color) = (1, 1, 1, 1)
    	
    	[Tooltip(Multiply Diffuse Color by texture.)]
        _MainTex ("Diffuse Texture", 2D) = "white" {}
    	
        [LargeHeader(Local Lighting)]
    	
    	[Header(Add Lighting)]
    	
    	[Tooltip(Add color to final lighting calculations. Alpha controls the VertexAO alpha and Matcap alpha.)]
        _LightingColor ("Add Lighting Color", Color) = (0,0,0,1)
    	
    	[Tooltip(Multiply Add Lighting Color by RGB color and alpha from texture.)]
    	_LightingColorTex ("Add Lighting Texture", 2D) = "white" {}
        
        [Header(MatCap)]
    	
    	[Tooltip(MatCap texture. Should use something otherwise it may look odd.)]
        _MatCapTex ("MatCap", 2D) = "black" {}
    	
    	[Tooltip(How much to multiply the MatCap with the lighting.)]
        _MatCapMult ("MatCap Multiply", Range(0,6)) = .5
    	
    	[Tooltip(How much to add the MatCap to the lighting.)]
        _MatCapAdd ("MatCap Add", Range(0,6)) = .02
    	
    	[Tooltip(Inset edges of MatCap to get rid of artifacts at edge of MatCap.)]
        _MatCapInset ("MatCap Inset", Range(0,1)) = .1
    	
    	[Header(AO Vertex Color)]
    	
    	[Tooltip(Amount to multiply the AO baked into vertices. You can bake this data with the Bake Vertex AO On Selected function in GTAvaUtil.)]
        _VertexColorBlend ("AO Vertex Color Alpha", Range(0,2)) = 0
    	
    	[Tooltip(Discard vertex if certex color alpha is below this threshold. Can use it to prevent avatar body from clipping through clothes. You can bake this data with the Bake Vertex Visibility Onto First Selected function in GTAvaUtil.)]
    	_DiscardVertexAOThreshold ("Discard Vertex AO Darkness Threshold", Range(0,.1)) = 0
        
        [Header(Rim Light)]
    	
    	[Tooltip(Threshold to start drawing rim light.)]
    	_RimAddGradientMin ("Rim Light Gradient Min", Range(.5,1.5)) = .8
    	
    	[Tooltip(Threshold by which the rim light will fade out.)]
        _RimAddGradientMax ("Rim Light Gradient Max", Range(.5,1.5)) = 1.5
    	
    	[Tooltip(Rim light color.)]
        _RimAddColor ("Rim Light Color", Color) = (1, 1, 1, 1)
    	
    	[Tooltip(Final rim light blend value.)]
        _RimAddColorBlend ("Rim Light Blend", Range(0,1)) = .05

    	[Header(Rim Darken)]
    	
    	[Tooltip(Threshold to start drawing rim darken.)]
        _RimMultiplyGradientMin ("Rim Darken Gradient Min", Range(.95,1.05)) = .995
    	
    	[Tooltip(Threshold by which the rim darken will fade out.)]
        _RimMultiplyGradientMax ("Rim Darken Gradient Max", Range(.95,1.05)) = 1
    	
    	[Tooltip(Utilize fwidth to apply additinal softness to rim darkening. Larger values will make it softer but will reveal block artifacts.)]
    	_RimMultiplyEdgeSoftness ("Rim Darken Edge Softness", Range(0,2)) = .5
            	    	
    	[LargeHeader(World Lighting)]
        
        [Header(Light Levels)]
    	
    	[Tooltip(Clip black level from world lighting.)]
        _DirectBlackLevel ("Black Level", Range(0,1)) = 0
    	
    	[Tooltip(Clip white levels from world lighting.)]
        _DirectWhiteLevel ("White Level", Range(0,1)) = .8
    	
    	[Tooltip(Compress black levels from world lighting upward.)]
        _DirectOutputBlackLevel ("Output Black Level", Range(0,1)) = .2
    	
    	[Tooltip(Compress white levels from world lighting downwards.)]
        _DirectOutputWhiteLevel ("Output White Level", Range(0,1)) = 1
    	
    	[Tooltip(Gamma of world lighting.)]
        _DirectGamma ("Gamma", Range(0,2)) = .5        
        
    	[Header(Light Probes)]
    	
    	[Tooltip(Average light probe values. 1 is fully averaged. 100 is no averaging.)]
    	_ProbeAverage ("Probe Average", Range(50,100)) = 80
    }	

	Subshader
    {
        Tags
        {
            "Queue" = "Geometry+15" 
        	"RenderType" = "Opaque"
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
	        #pragma skip_variants DYNAMICLIGHTMAP_ON LIGHTMAP_ON LIGHTMAP_SHADOW_MIXING DIRLIGHTMAP_COMBINED
	        
	        #include "UnityCG.cginc"
	        #include "AutoLight.cginc"
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
            	float3 worldPosition : POSITION1;
            	float4 scrPos : POSITION2;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float4 color : COLOR0;
            	centroid float3 worldNormal : NORMAL0;

            	UNITY_SHADOW_COORDS(7)
            	
                UNITY_VERTEX_OUTPUT_STEREO
            };

			sampler2D _MainTex;
			float4 _MainTex_ST;
            float4 _Color;
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

            	UNITY_TRANSFER_LIGHTING(o, v.uv1);
            	
                return o;
            }

            float4 frag(v2f i) : SV_Target
            {
            	const float3 normalizedWorldSpaceNormal = normalize(i.worldNormal);
            	
                float4 sample = tex2D(_MainTex, TRANSFORM_TEX(i.uv0, _MainTex)) * _Color;
                float3 diffuse = sample.xyz;

            	UNITY_LIGHT_ATTENUATION(attenuation, i, normalizedWorldSpaceNormal);
            	applyLighting(diffuse, i.uv0, attenuation, normalizedWorldSpaceNormal, i.worldPosition, i.color);
                
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