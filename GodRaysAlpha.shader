Shader "Custom/GodRaysAlpha"
{
    Properties
    {
        _MainTex ("Background Texture", 2D) = "white" {}
        _TimeSpeed ("Time Speed", Float) = 1.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float _TimeSpeed;

            // --- God Ray constants ---
            #define GOD_RAY_LENGTH 1.1
            #define GOD_RAY_FREQUENCY 28.0

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float GodRays(float2 ndc, float2 uv, float t)
            {
                float2 godRayOrigin = ndc + float2(1.5, -1.25);
                float rayInputFunc = atan2(godRayOrigin.y, godRayOrigin.x) * 0.63661977236; // 2/pi
                float light = (sin(rayInputFunc * GOD_RAY_FREQUENCY + t * -2.25) * 0.5 + 0.5);
                light = 0.5 * (light + (sin(rayInputFunc * 13.0 + t) * 0.5 + 0.5));
                light *= pow(saturate(dot(normalize(-godRayOrigin), normalize(ndc - godRayOrigin))), 2.5);
                light *= pow(uv.y, GOD_RAY_LENGTH);
                light = pow(light, 1.75);
                return light;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 uv = i.uv;
                float2 ndc = (2.0 * i.vertex.xy / _ScreenParams.xy - 1.0) * (_ScreenParams.x / _ScreenParams.y);

                float t = _Time.y * _TimeSpeed;

                float godRay = GodRays(ndc, uv, t);

                // Background
                float3 bgColor = tex2D(_MainTex, uv).rgb * 0.2;

                // Light color
                float3 lightColor = lerp(float3(1,1,0.5), float3(0.55,0.55,0.95)*0.95, 1.0 - uv.y);

                float3 finalColor = lerp(bgColor, lightColor, (godRay + 0.05)/1.05);

                // --- önemli kýsým: alpha ýþýða göre ayarlanýyor ---
                return float4(finalColor, godRay);
            }
            ENDCG
        }
    }
}
