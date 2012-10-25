//Copyright (C) 2012 Chirag Raman

//This file is part of Projection-Mapping-in-Unity3D.

//Projection-Mapping-in-Unity3D is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.

//Projection Mapping in Unity3D is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.

//You should have received a copy of the GNU General Public License
//along with Projection-Mapping-in-Unity3D.  If not, see <http://www.gnu.org/licenses/>

Shader "Custom/HomographyOren-NayarTransparentDiffuse" {
	Properties {
		_Color ("Main Color", Color) = (1,1,1,1)
		_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
		_Roughness ("Roughness", range(0,1)) = 0.5
		matrixRow_1 ("matrixRow_1", Vector) = (1, 0, 0, 0)
		matrixRow_2 ("matrixRow_2", Vector) = (0, 1, 0, 0)
		matrixRow_3 ("matrixRow_3", Vector) = (0, 0, 1, 0)
		matrixRow_4 ("matrixRow_4", Vector) = (0, 0, 0, 1)
		
	}

    CGINCLUDE

        struct SurfaceOutput {
		    half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Specular;
			half Gloss;
			half Alpha;
        };

        float4 _LightColor0;
        float4 _SpecColor;

        float _Roughness;

        
        inline half4 LightingOrenNayar (SurfaceOutput s, half3 lightDir, half3 viewDir, half atten) {

            #ifndef USING_DIRECTIONAL_LIGHT
            lightDir = normalize(lightDir);
            #endif

            half3 n = s.Normal;
            half3 l = lightDir;
            half3 v = normalize(viewDir);

            half gamma = dot(v - n*dot(v, n), l - n*dot(l, n));

            half rough_sq = _Roughness * _Roughness;

            half a = 1 - 0.5 * (rough_sq / (rough_sq + 0.57));

            half b = 0.45 * (rough_sq / (rough_sq + 0.09));

            half alpha = max(acos(dot(v, n)), acos(dot(l, n)));
            half beta  = min(acos(dot(v, n)), acos(dot(l, n)));

            half C = sin(alpha)*tan(beta);

            half3 final = (a + b*max(0, gamma)*C);

            return half4(2*atten*_LightColor0.rgb*s.Albedo*max(0, dot(n,l))*final, 1);

        }

    ENDCG

    
	SubShader {
		Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
		ZWrite Off
		Alphatest Greater 0
		LOD 200
		ColorMask RGB
		Fog { Color [_AddFog] }
		
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha
			Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_fwdbase
            #pragma target 3.0
            #include "HLSLSupport.cginc"
            #include "AutoLight.cginc"
			#include "UnityCG.cginc"

			float4 _Color;
			sampler2D _MainTex;
			float4 matrixRow_1;
			float4 matrixRow_2;
			float4 matrixRow_3;
			float4 matrixRow_4;

			struct v2f {
				float4 pos : SV_POSITION;
				float2 packuv0 : TEXCOORD0;
                #ifdef LIGHTMAP_OFF
                    float3 normal : TEXCOORD1;
                #endif
                #ifndef LIGHTMAP_OFF
                    float2 lightmapUV : TEXCOORD2;
                #else
                    float3 lightDir : TEXCOORD2;
                    float3 shlight : TEXCOORD3;
                    float3 viewDir : TEXCOORD4;
                #endif
                LIGHTING_COORDS(5,6)
			};

			float4 _MainTex_ST;

			 #ifndef LIGHTMAP_OFF
				float4 unity_LightmapST;
             #endif

			v2f vert (appdata_full v)
			{	
				float4x4 matrixH = { matrixRow_1.x, matrixRow_1.y, matrixRow_1.z, matrixRow_1.w,
								  matrixRow_2.x, matrixRow_2.y, matrixRow_2.z, matrixRow_2.w,
								  matrixRow_3.x, matrixRow_3.y, matrixRow_3.z, matrixRow_3.w,
								  matrixRow_4.x, matrixRow_4.y, matrixRow_4.z, matrixRow_4.w };

				v2f o;
				o.pos = mul (UNITY_MATRIX_MVP,  v.vertex);
				o.pos = o.pos / o.pos.w;
				o.pos = mul (matrixH,o.pos);
				o.pos.x = o.pos.x / o.pos.w;
				o.pos.y = o.pos.y / o.pos.w;
				o.pos.w = o.pos.w / o.pos.w;
			    o.packuv0.xy = TRANSFORM_TEX (v.texcoord, _MainTex);
				#ifndef LIGHTMAP_OFF
                    o.lightmapUV.xy = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
                #endif
                #ifdef LIGHTMAP_OFF
                    o.normal = v.normal;
                    o.lightDir = ObjSpaceLightDir( v.vertex );
                    o.viewDir = ObjSpaceViewDir( v.vertex );
                #endif
                #ifdef LIGHTMAP_OFF
                    float3 shlight = ShadeSH9 (float4(v.normal,1.0));
                    o.shlight = shlight;
                #endif
                TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}

			#ifndef LIGHTMAP_OFF
               sampler2D unity_Lightmap;
               sampler2D unity_LightmapInd;
            #endif

			half4 frag (v2f IN) : COLOR
			{
				float2 uv_MainTex = IN.packuv0.xy;
                SurfaceOutput o;
                half4 c = tex2D(_MainTex, uv_MainTex) * _Color;
                o.Albedo = c.rgb;
                o.Alpha = c.a;

                #ifdef LIGHTMAP_OFF
	                 o.Normal = IN.normal;
                #endif

                half atten = LIGHT_ATTENUATION(IN);

                #ifdef LIGHTMAP_OFF
	                  c = LightingOrenNayar (o, IN.lightDir, IN.viewDir, atten);
					  c.rgb += o.Albedo * IN.shlight;
					  c.a = o.Alpha;
                #else
                      half3 lmFull = tex2D (unity_Lightmap, IN.lightmapUV.xy).rgb * 2.0;
					  #ifdef SHADOWS_SCREEN
						  c.rgb = o.Albedo * min(lmFull, atten*2);
					  #else
					      c.rgb = o.Albedo * lmFull;
                      #endif
                      c.a = o.Alpha;
                #endif
                return c;
			}

			ENDCG
		}
	
		Pass {
		    Name "FORWARD"
            Blend One One
            Tags { "LightMode" = "ForwardAdd" }

            CGPROGRAM
			    #pragma vertex vert
                #pragma fragment frag
                #pragma multi_compile_fwdadd
                #pragma target 3.0
                #include "HLSLSupport.cginc"
                #include "UnityCG.cginc"
                #include "AutoLight.cginc"

                sampler2D _MainTex;
                float4 _Color;
                float4 matrixRow_1;
				float4 matrixRow_2;
				float4 matrixRow_3;
				float4 matrixRow_4;
				
				struct v2f {
                    float4 pos : SV_POSITION;
                    float2 packuv0 : TEXCOORD0;
                    float3 normal : TEXCOORD1;
                    float3 lightDir : TEXCOORD2;
					float3 viewDir : TEXCOORD3;
					LIGHTING_COORDS(4,5)
                };

               float4 _MainTex_ST;
			   
			   v2f vert (appdata_full v) {
			   	   float4x4 matrixH = { matrixRow_1.x, matrixRow_1.y, matrixRow_1.z, matrixRow_1.w,
									  matrixRow_2.x, matrixRow_2.y, matrixRow_2.z, matrixRow_2.w,
									  matrixRow_3.x, matrixRow_3.y, matrixRow_3.z, matrixRow_3.w,
									  matrixRow_4.x, matrixRow_4.y, matrixRow_4.z, matrixRow_4.w };
                    v2f o;
					o.pos = mul (UNITY_MATRIX_MVP,  v.vertex);
					o.pos = o.pos / o.pos.w;
					o.pos = mul (matrixH, o.pos);
					o.pos.x = o.pos.x / o.pos.w;
					o.pos.y = o.pos.y / o.pos.w;
					o.pos.w = o.pos.w / o.pos.w;
                    o.normal = v.normal;
                    o.packuv0.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                    o.lightDir = ObjSpaceLightDir( v.vertex );
                    o.viewDir = ObjSpaceViewDir( v.vertex );
                    TRANSFER_VERTEX_TO_FRAGMENT(o);
                    return o;
                }

               half4 frag (v2f IN) : COLOR {
			        float2 uv_MainTex = IN.packuv0.xy;
					SurfaceOutput o;
                    o.Alpha = 0.0;
                    half4 c = tex2D(_MainTex, uv_MainTex) * _Color;
                    o.Albedo = c.rgb;
                    o.Alpha = c.a;
                    o.Normal = IN.normal;
                    c = LightingOrenNayar (o, IN.lightDir, IN.viewDir, LIGHT_ATTENUATION(IN));
                    return c;
                }

            ENDCG
        }

	}
	 
	FallBack "Diffuse"
}
