/*
*      Author: Starking.
*      Version: 18.01.29
*/

Shader "RO/Scene/Water" {
	Properties {
		[NoScaleOffset] _WaterColor ("渐变颜色映射图（横向）", 2D) = "gray" {}
		[Normal]_BumpMap ("水纹 (法线)", 2D) = "bump" {}
		_WaveScale("水波参数(1平铺,2平铺,比重,强度)", Vector) = (0.063,0.25,0.5,1)
		_WaveSpeed("流速 (1x,1y,2x,2y)", Vector) = (19,9,-16,-7)

		[Space]
		[Toggle(USE_VECTOR_COLOR)] _UseVectorColor("用顶点色代替深度", Float) = 0
		_VectorColorScale("顶点色对应深度", range(0.01, 10)) = 1

		[Space]
		[HDR]_NearColor("岸边色", COLOR) = (0.26, 1.6, 1.1, 1)
		_DepthFade("岸边变色宽度", range(0.01, 30)) = 0.4
        _AlphaFade("岸边透明宽度", range(0.01, 30)) = 0.1
		_NearBlur("岸边软边", Range(0.01,1)) = 0.01

		[Space]
		[HDR]_FarColor("地平线虚化色", COLOR) = (0.26, 1.6, 1.1, 1)
		_BlurStart("地平线虚化起始", Float) = 150
		_BlurEnd("地平线虚化结束", Float) = 300
		
		[Space]
		[HDR]_ReflectionColor("反射颜色", COLOR) = (1,1,1,0.5)
		_WaterClarity("清澈度（反射范围）", range(0,5)) = 2.5
		_ReflectDistort("反射扭曲", Range(0,1)) = 0.2
		_SSPRDistort("SSPR扭曲", Range(1,10)) = 5
		_ReflectionTex("反射球纹理", CUBE) = "" {}
		[HDR]_ReflectionTexColor("反射球颜色", Color) = (1,1,1,0)

		[Space]
		_FoamTex ("泡沫纹理", 2D) = "black" {}
		[HDR]_FoamColor("泡沫颜色", color) = (1.1,1.1,1.1,1)
		_FoamFade("泡沫宽度", range(0,5)) = 1
		_FoamFadePow("边缘泡沫增强", range(0,2)) = 1.25
		_FoamHeadWidth("边缘白边宽度", range(0,1)) = 0.2
		_FoamBlur("泡沫软边", Range(0.01,1)) = 0.01
		_FoamDistort("泡沫扭曲", Range(0,1)) = 0.5
		_FoamWave("泡沫起伏", Range(0,1)) = 0.05

		[Space]
		_WaveRandomMap("水面起伏噪波", 2D) = "black" {}
		_WaveLoopPower("水面起伏强度", range(0, 2)) = 0.5
		_WaveLoopRandom("水面起伏随机强度", range(0, 1)) = 1
		_WaveLoopSpeed("水面起伏速度", range(0, 4)) = 1
		
		[Space]
		[Toggle(TWO_WAVE)]_Wave2Mode("激活第二个波浪", Float) = 0
		_Wave2LoopPower("波浪2范围", range(0, 2)) = 0.5
		_Wave2LoopRandom("波浪2随机范围", range(0, 1)) = 1
		_Wave2LoopFadeSpeed("波浪2渐现速度", range(0, 8)) = 4
		_Wave1LoopFadeSpeed("波浪1消退速度", range(0, 2)) = 1

		[Space]
		_SpecularColor("高光颜色", color) = (1,1,1,1)
		_FogFactor("雾影响", Range(0,1)) = 1
	}

	HLSLINCLUDE

	#define SCENE_MAP_ON

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "../Include/SceneMap.cginc"

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SoftColorSpaceLinear.hlsl"
	
	CBUFFER_START(UnityPerMaterial)
	half _VectorColorScale;
	TEXTURE2D(_FoamTex); SAMPLER(sampler_FoamTex); half4 _FoamTex_ST;
	half _FoamDistort;
	TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);
	TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_PointClamp);
	half _DepthFade;
    half _AlphaFade;
	half _FoamFade;
	half _FoamFadePow;
	half _FoamWave;
	half _FoamHeadWidth;
	half _FoamBlur;
	TEXTURE2D(_WaveRandomMap); SAMPLER(sampler_WaveRandomMap); half4 _WaveRandomMap_ST;

	half4 _NearColor;
	half _NearBlur;

	TEXTURE2D(_MirrorReflectionTex); SAMPLER(sampler_MirrorReflectionTex);
    half4 _ReflectionTexColor;
	half4 _SpecularColor;
	half4 _ReflectionColor;
	half4 _FoamColor;
	half _FogFactor;
    half4 _FarColor;
    half _BlurStart;
	half _BlurEnd;
	half _WaterClarity;
	TEXTURECUBE(_ReflectionTex); SAMPLER(sampler_ReflectionTex);
	half4 _ReflectionTex_HDR;
	half _ReflectDistort;
	half _SSPRDistort;
	TEXTURE2D(_WaterColor); SAMPLER(sampler_WaterColor);
	TEXTURE2D(_BumpMap); SAMPLER(sampler_BumpMap);
    half4 _WaveScale;
    half4 _WaveSpeed;
	half _WaveLoopPower;
	half _WaveLoopSpeed;
	half _WaveLoopRandom;
	half _Wave2LoopPower;
	half _Wave2LoopRandom;
	half _Wave2LoopFadeSpeed;
	half _Wave1LoopFadeSpeed;
	CBUFFER_END

	half _EnabldMirrorReflection;
	half4 _ROCSunColor;
	half4 _ROCAmbientColor;

	static const half G = -0.999;
	static const half G2 = 0.998001;

	struct appdata
	{
		float3 pos : POSITION;
        half4 color : COLOR;
	};

	struct v2f
	{
		float4 pos : SV_POSITION;
		float4 worldPos : TEXCOORD0;
		float4 bumpUV : TEXCOORD1;
        float viewDepth : TEXCOORD2;
        half4 color : COLOR;

		#ifndef DISABLE_DEPTH_TEXTURE
			float4 screenUV : TEXCOORD3;
		#endif
		SCENE_PARAM_COORDS(4, 5)
		
		float4 shadowCoord : TEXCOORD6;
	};

	v2f vert(appdata v)
	{
		v2f o;
        o.color = v.color;
		o.worldPos = mul(GetObjectToWorldMatrix(), float4(v.pos, 1));
        o.viewDepth = -mul(GetWorldToViewMatrix(), o.worldPos).z;

		float4 bump = (o.worldPos.xzxz + _WaveSpeed * _Time.xxxx) * _WaveScale.xxyy;
    	o.bumpUV = bump.xywz + float4(0, 0.5, 0.2, 0.1);

        o.pos = TransformObjectToHClip(v.pos.xyz);
		#ifndef DISABLE_DEPTH_TEXTURE
			o.screenUV = ComputeScreenPos(o.pos);
		#endif

		#if defined(SCENE_MAP_ON)
			float3 viewDir = _WorldSpaceCameraPos.xyz - o.worldPos.xyz;
			GET_SCENE_PARAM(o) 
			TRANSFER_SCATTER(o, -viewDir, o.worldPos.y)
			o.sceneMapCoord = 0;
		#endif

		VertexPositionInputs vertexInput = GetVertexPositionInputs(v.pos.xyz);
		o.shadowCoord = GetShadowCoord(vertexInput);
		
		return o;
	}

	half2 ViewPosToCS(half3 vpos)
	{
		half4 proj_pos = mul(unity_CameraProjection, half4(vpos, 1));
		half3 screenPos = proj_pos.xyz / proj_pos.w;
		return half2(screenPos.x, screenPos.y) * 0.5 + 0.5;
	}

	half compareWithDepth(half3 vpos)
	{
		half2 uv = ViewPosToCS(vpos);
		half depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_PointClamp, uv);
		depth = LinearEyeDepth(depth, _ZBufferParams);
		int isInside = uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1;
		return lerp(0, vpos.z + depth, isInside);
	}

	bool RayMarching(half3 o, half3 r, out half2 hitUV)
	{
		half3 end = o;
		half stepSize = 2;
		half thinkness = 1.5;
		half triveled = 0;
		int max_marching = 256;
		half max_distance = 500;

		UNITY_LOOP
		for (int i = 1; i <= max_marching; ++i)
		{
			end += r * stepSize;
			triveled += stepSize;

			if (triveled > max_distance)
				return false;

			half collied = compareWithDepth(end);
			if (collied < 0)
			{
				if (abs(collied) < thinkness)
				{
					hitUV = ViewPosToCS(end);
					return true;
				}

				//回到当前起点
				end -= r * stepSize;
				triveled -= stepSize;
				//步进减半
				stepSize *= 0.5;
			}
		}
		return false;
	}

	half4 frag(v2f i) : SV_Target
	{
		half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
        half viewDepth = i.viewDepth;

		half bgAlpha = 1 - i.color.a;

		// normal
		half2 bumpP = saturate(_WaveScale.zw);
        half3 bump1 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV.xy));
		half3 bump2 = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV.zw));
        half3 bump = lerp(bump1, bump2, bumpP.x);
		bump.xy *= bumpP.y;

		// reflection
		half2 reflectDistort = bump.xy * _ReflectDistort;
		half3 normal = normalize(bump);
    	half3 cubeColor = DecodeHDREnvironment(SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflect(viewDir, normal)), _ReflectionTex_HDR).rgb;

        // blur
		half blur = 1 - saturate((viewDepth - _BlurStart) / (_BlurEnd - _BlurStart));

		// fresnel
		half fresnel = pow(1.0 - saturate(dot(half3(0, 1, 0), viewDir)), _WaterClarity);

		// color
		half3 baseColor = SAMPLE_TEXTURE2D(_WaterColor, sampler_WaterColor, half2(fresnel, 0.5)).rgb;

		// specular
		half3 specularDir = normalize(reflect(viewDir, normal));
		half cosine = dot(_ROCLightDir1 * half3(1,-1,-1), specularDir);
		half miePhase = 1.5 * ((1.0 - G2) / (2.0 + G2)) * (1.0 + cosine * cosine) / pow(abs(1.0 + G2 - 2.0 * G * cosine), 1.5);

		half waveclip = 0;
		half3 color = 0;
		half3 reflectLight = 0;
		
		#ifndef DISABLE_DEPTH_TEXTURE
			
			// depth fade
			half2 screenUV = i.screenUV.xy / i.screenUV.w;
			half viewAngle = abs(dot(half3(0, 1, 0), viewDir));
			half viewSpaceDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_PointClamp, screenUV);
			#ifdef USE_VECTOR_COLOR
				half depthDiff = i.color.r * _VectorColorScale;
				half viewAngleFix = 1;
			#else
				half sceneViewDepth = LinearEyeDepth(viewSpaceDepth, _ZBufferParams);
				half depthDiff = sceneViewDepth - viewDepth;
				depthDiff *= lerp(0.5, 1.5, viewAngle);
				half viewAngleFix = lerp(1, 0.5, viewAngle);
			#endif
			half baseDepthDiff = depthDiff;
			half noiseWave = SAMPLE_TEXTURE2D(_WaveRandomMap, sampler_WaveRandomMap, i.bumpUV.xy * _WaveRandomMap_ST.xy + _WaveRandomMap_ST.zw).r;
			half noise = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, (i.bumpUV.xy + bump.xy * _FoamDistort) * _FoamTex_ST.xy + _FoamTex_ST.zw).r;
			half baseTime = _Time.y * _WaveLoopSpeed + noiseWave * PI * 2 * _WaveLoopRandom;

			// wave
			#ifdef TWO_WAVE
				half depthOffset = noise * _FoamWave + _WaveLoopPower * (1 - abs(sin(baseTime * 0.5)));
				half waveAlpha = saturate(lerp(1 - _Wave1LoopFadeSpeed, 1, (1 - frac(baseTime / PI / 2.0)) * 2));
			#else
				half depthOffset = noise * _FoamWave + _WaveLoopPower * (sin(baseTime) * 0.5 + 0.5);
				half waveAlpha = 1;
			#endif
			depthDiff = depthDiff - depthOffset;

			waveclip = smoothstep(depthDiff, depthDiff + _NearBlur, 0);
			depthDiff = max(0, depthDiff);
			
			// foam
			half foam_cutoff = pow(saturate(depthDiff / _FoamFade), _FoamFadePow) - step(depthDiff, _FoamHeadWidth);
			half foam = smoothstep(foam_cutoff, foam_cutoff + _FoamBlur, noise) * waveAlpha;
			#ifdef TWO_WAVE
				// wave2
				half wave2alpha = frac(baseTime * 0.5 / PI);
				half depthOffset2 = noise * _FoamWave + _WaveLoopPower + noiseWave * _Wave2LoopRandom * (1 - wave2alpha) + _Wave2LoopPower * PI * (1 - wave2alpha);
				half depthDiff2 = baseDepthDiff - depthOffset2;
				half waveclip2 = smoothstep(depthDiff2, depthDiff2 + _NearBlur, 0);
				depthDiff2 = max(0, depthDiff2);
				half foam_cutoff2 = pow(saturate(depthDiff2 / _FoamFade), _FoamFadePow) - step(depthDiff2, _FoamHeadWidth);
				half foam2 = smoothstep(foam_cutoff2, foam_cutoff2 + _FoamBlur, noise);
				
				foam = max(foam, foam2 * (1 - waveclip2) * saturate(wave2alpha * _Wave2LoopFadeSpeed));
				bgAlpha = lerp(1, bgAlpha, max(waveAlpha, 1 - waveclip2));
			#endif
			half colorFade = saturate(depthDiff / _DepthFade);
			half alphaFade = saturate(depthDiff / _AlphaFade);

			colorFade = pow(colorFade, 0.5 * viewAngleFix);
			alphaFade = pow(alphaFade, 0.5 * viewAngleFix);
	
			half3 waterColor = lerp(_NearColor.rgb, baseColor.rgb, colorFade);
			bgAlpha = lerp(1, bgAlpha, alphaFade);

			// refraction
			//half2 refractDistort = bump.xy * _RefractDistort;
			//half2 refractUV = screenUV + lerp(0, refractDistort, colorFade);
			//refractUV.x = clamp(refractUV.x, 0.001, 0.999);
			//refractUV.y = clamp(refractUV.y, 0.001, 0.999);
			//half3 refractColor = lerp(tex2D(_GrabTexture, refractUV).rgb, waterColor, colorFade);

			// reflection
			half3 reflectColor = half3(0, 0, 0);
			if (_EnabldMirrorReflection == 0)
			{
				// SSPR
				// vsRay is a vector from camera to zFar
				// sceneViewDepth01 is the proportion of distance between camera to zFar
				// vsRay * sceneViewDepth01 is the intersection of viewDirection and water
				half3 rayOrigin = TransformWorldToViewDir(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
				half3 viewSpaceNormal = TransformWorldToViewDir(normalize(half3(bump.x * _SSPRDistort, 1, bump.y * _SSPRDistort)));
				half3 reflectionDir = normalize(reflect(rayOrigin, viewSpaceNormal));
				half2 hitUV = 0;
				half3 hitColor = half3(0, 0, 0);
				if (RayMarching(rayOrigin, reflectionDir, hitUV))
				{
					hitColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, hitUV).xyz; //half3(1, 1, 1);
					//hitColor = lerp(cubeColor * _ReflectionTexColor.rgb, hitColor, 1 - _ReflectionTexColor.a);
				}
				else 
				{
					hitColor = cubeColor;
				}
				reflectColor = hitColor;
			}
			else 
			{
				half2 reflectUV = screenUV + reflectDistort;
				reflectColor = SAMPLE_TEXTURE2D(_MirrorReflectionTex, sampler_MirrorReflectionTex, reflectUV).rgb;
				#if UNITY_COLORSPACE_GAMMA
				reflectColor = FastSRGBToLinear(reflectColor);
				#endif
				reflectColor = lerp(cubeColor * _ReflectionTexColor.rgb, reflectColor, 1 - _ReflectionTexColor.a);
			}
			
			// final color
			color = waterColor * (1 - fresnel * _ReflectionColor.a) * (1 - bgAlpha);
			reflectLight = reflectColor * _ReflectionColor.rgb * (fresnel * _ReflectionColor.a) * (1 - bgAlpha);

			foam = saturate(foam * _FoamColor.a);
			color = lerp(color, _FoamColor.rgb, foam);
			bgAlpha *= 1 - foam;
		#else
			color = lerp(baseColor, cubeColor * _ReflectionColor.rgb, fresnel * _ReflectionColor.a);
        #endif

		color *= lerp(_FarColor.rgb, 1, blur);

		Light mainLight = GetMainLight(i.shadowCoord, i.worldPos);
		half atten = mainLight.distanceAttenuation * mainLight.shadowAttenuation * max(dot(half3(0,1,0), mainLight.direction.xyz),0);

		half3 sunColor = _ROCSunColor.rgb * min(2, miePhase * saturate((bump1.r - bump2.g) * bump2.r));
		sunColor += pow(saturate(dot(mainLight.direction.xyz * half3(-1, 1, 1), specularDir)), 100) * 0.25;

		half3 specularColor = mainLight.color * sunColor * _SpecularColor.rgb * (1 - bgAlpha);

		#if defined(SCENE_MAP_ON)
			#ifdef UNITY_COLORSPACE_GAMMA
				color = FastSRGBToLinear(color);
			#endif
			baseColor = color.rgb;
			#if defined(LIGHTPROBE_SH)
				half4 bakeGI = SampleSHVertex(0);
			#else
				half4 bakeGI = _ROCAmbientColor;
			#endif
			color.rgb = baseColor * (bakeGI.rgb + mainLight.color * atten);
			#if defined(SCENE_MAP_RAIN)
				color.rgb += baseColor * GetLightningColor(i.worldPos) * 3;
			#endif
			color.rgb += specularColor;
			ApplySceneColor(color.rgb);
			ApplyCloudMask(color, i.sceneMapCoord.z);
			color.rgb += reflectLight;
			APPLY_SCENE_FOG(color, i, _FogFactor);
			// try to soft colorSpace linear 
			color.rgb = LinearColorToProcessColor(color.rgb);
		#endif
		
		color *= 1 - waveclip;
		bgAlpha = lerp(bgAlpha, 1, waveclip);
		return half4(color, 1 - bgAlpha);
	}
	ENDHLSL

	Subshader {
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 400

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One OneMinusSrcAlpha
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			// #pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.5
			#pragma exclude_renderers gles
			#pragma shader_feature _MAIN_LIGHT_SHADOWS
			#pragma shader_feature _SHADOWS_SOFT
			#pragma multi_compile __ DISABLE_DEPTH_TEXTURE
			#pragma multi_compile __ SCENE_MAP_RAIN
			#pragma shader_feature_local __ TWO_WAVE
			#pragma shader_feature_local __ USE_VECTOR_COLOR
			ENDHLSL
		}
	}

	Subshader {
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 300

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One OneMinusSrcAlpha
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			// #pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.5
			#pragma exclude_renderers gles
			ENDHLSL
		}
	}

	Subshader {
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 100

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One OneMinusSrcAlpha
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			// #pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}
	Fallback Off
}
