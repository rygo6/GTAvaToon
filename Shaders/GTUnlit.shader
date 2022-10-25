Shader "GeoTetra/GTAvaToon/IgnoreOutline/GTUnlit"
{
    Properties
    {
        _Color ("Main Color", Color) = (1, 1, 1, 1)
        _Expand ("Vertex Expand", Float) = 0
    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry+15" 
            "RenderType" = "Opaque" 
            "IgnoreProjector" = "True"
        }

        Pass
        {
            HLSLPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma skip_variants LIGHTMAP_ON DYNAMICLIGHTMAP_ON LIGHTMAP_SHADOW_MIXING SHADOWS_SHADOWMASK DIRLIGHTMAP_COMBINED

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            float4 _Color;
            float _Expand;

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                float3 vert = v.vertex.xyz + normalize(v.normal) * _Expand * .001;
                o.vertex = UnityObjectToClipPos(float4(vert, 1));
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return _Color;
            }
            ENDHLSL
        }
    }
}
