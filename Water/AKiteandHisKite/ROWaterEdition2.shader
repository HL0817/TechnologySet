/*
*      Author: Vern LH
*      Version: 2022.6.27
*/

Shader "RO/Scene/WaterEdition2" {
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
		float3 position : POSITION;
        half4 color : COLOR;
	};

	struct v2f
	{
		float4 position : SV_POSITION;
		float4 worldPos : TEXCOORD0;
		float4 bumpUV : TEXCOORD1;
        float viewDepth : TEXCOORD2;
        half4 color : COLOR;

		float4 screenUV : TEXCOORD3;

		SCENE_PARAM_COORDS(4, 5)
		
		float4 shadowCoord : TEXCOORD6;
	};

	v2f vert(appdata v)
	{
		v2f o;
        o.color = v.color;
		o.worldPos = mul(GetObjectToWorldMatrix(), float4(v.position, 1));
        o.viewDepth = -mul(GetWorldToViewMatrix(), o.worldPos).z;

		float4 bump = (o.worldPos.xzxz + _WaveSpeed * _Time.xxxx) * _WaveScale.xxyy;
    	o.bumpUV = bump.xywz + float4(0, 0.5, 0.2, 0.1);

        o.position = TransformObjectToHClip(v.position.xyz);
		o.screenUV = ComputeScreenPos(o.position);

		float3 viewDir = _WorldSpaceCameraPos.xyz - o.worldPos.xyz;
		GET_SCENE_PARAM(o) 
		TRANSFER_SCATTER(o, -viewDir, o.worldPos.y)
		o.sceneMapCoord = 0;

		VertexPositionInputs vertexInput = GetVertexPositionInputs(v.position.xyz);
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

	// depth info
	struct DepthInfo
	{
		half vertexViewDepth;	// depth of vertex in view space
		half screenViewDepth;	// depth of screenUV (sample depth from view depth texture)
		half waterViewDepth;		// distance between vertex and the intersection of view direction
		half waterBottomDepth;  	// distance between watersurface and bottom of view direction
	};
	DepthInfo GetDepthInfo(half viewDepth, half2 screenUV, half3 worldPos)
	{
		DepthInfo depthInfo;

		depthInfo.vertexViewDepth = viewDepth;

		depthInfo.screenViewDepth = viewDepth;
		depthInfo.screenViewDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_PointClamp, screenUV), _ZBufferParams);

		depthInfo.waterViewDepth = abs(depthInfo.screenViewDepth - viewDepth);

		// similar triangles
		half waterCameraWorldDistance = distance(_WorldSpaceCameraPos.xyz, worldPos.xyz);
		half waterCameraXZDistance = abs(_WorldSpaceCameraPos.y - worldPos.y);
		depthInfo.waterBottomDepth = (waterCameraXZDistance * depthInfo.waterViewDepth) / waterCameraWorldDistance;

		return depthInfo;
	}

	half3 GetSpecularColor(Light mainLight, half3 specularDirection, half3 horizonOffset, half3 verticalOffset)
	{
		half cosine = dot(_ROCLightDir1 * half3(1,-1,-1), specularDirection);
		half miePhase = 1.5 * ((1.0 - G2) / (2.0 + G2)) * (1.0 + cosine * cosine) / pow(abs(1.0 + G2 - 2.0 * G * cosine), 1.5);
		half3 sunColor = _ROCSunColor.rgb * min(2, miePhase * saturate((horizonOffset.r - verticalOffset.g) * verticalOffset.r));
		sunColor += pow(saturate(dot(mainLight.direction.xyz * half3(-1, 1, 1), specularDirection)), 100) * 0.25;

		half3 specularColor = mainLight.color * sunColor * _SpecularColor.rgb;
		return specularColor;
	}

	half3 GetReflectColor(half2 screenUV, half3 skyCubeColor, half2 offset, half3 worldPos)
	{
		half3 reflectColor = half3(0, 0, 0);
		// SSPR
		if (_EnabldMirrorReflection == 0)
		{
			// view space params
			half3 VSIncidentDirection = TransformWorldToViewDir(worldPos.xyz - _WorldSpaceCameraPos.xyz);
			half3 VSReflectNormal = TransformWorldToViewDir(normalize(half3(offset.x * _SSPRDistort, 1, offset.y * _SSPRDistort)));
			half3 VSReflectionDirection = normalize(reflect(VSIncidentDirection, VSReflectNormal));
			half2 hitUV = 0;
			half3 hitColor = skyCubeColor;
			if (RayMarching(VSIncidentDirection, VSReflectionDirection, hitUV))
			{
				hitColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, hitUV).xyz;
			}
			reflectColor = hitColor;
		}
		else 
		{
			// Mirror Reflection params
			half2 reflectUV = screenUV + offset.xy * _ReflectDistort;
			reflectColor = SAMPLE_TEXTURE2D(_MirrorReflectionTex, sampler_MirrorReflectionTex, reflectUV).rgb;
			#if UNITY_COLORSPACE_GAMMA
			reflectColor = FastSRGBToLinear(reflectColor);
			#endif
			reflectColor = lerp(skyCubeColor * _ReflectionTexColor.rgb, reflectColor, 1 - _ReflectionTexColor.a);
		}

		return reflectColor;
	}

	struct NearAndFoamColorParams
	{
		half colorFade;
		half alphaFade;
		half foam;
		half waveAlphaFactor;
		half waveClip;
	};
	NearAndFoamColorParams GetNearAndFoamColorParams(half4 bumpUV, half3 offset, half waterViewDepth, half viewAngle)
	{
		half baseWaterVSDepth = waterViewDepth;
		// baseWaterVSDepth *= lerp(0.5, 1.5, 1 - viewAngle);
		half fixViewAngle = lerp(0.5, 1, viewAngle);
		half waveNoise = SAMPLE_TEXTURE2D(_WaveRandomMap, sampler_WaveRandomMap, bumpUV.xy * _WaveRandomMap_ST.xy + _WaveRandomMap_ST.zw).r;
		half foamNoise = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, (bumpUV.xy + offset.xy * _FoamDistort) * _FoamTex_ST.xy + _FoamTex_ST.zw).r;
		half waveOffset = _Time.y * _WaveLoopSpeed + waveNoise * PI * 2 * _WaveLoopRandom;

		#ifdef TWO_WAVE
		half waterDepthOffset = foamNoise * _FoamWave + _WaveLoopPower * (1 - abs(sin(waveOffset * 0.5)));
		half waveAlpha = saturate(lerp(1 - _Wave1LoopFadeSpeed, 1, (1 - frac(waveOffset / PI / 2.0)) * 2));
		#else
		half waterDepthOffset = foamNoise * _FoamWave + _WaveLoopPower * (sin(waveOffset * 0.5) + 0.5);
		half waveAlpha = 1;
		#endif
		half waterVSDepth = baseWaterVSDepth - waterDepthOffset;
		half waveClip = smoothstep(waterVSDepth, waterVSDepth + _NearBlur, 0);
		waterVSDepth = max(0, waterVSDepth);

		half foamCutoff = pow(saturate(waterVSDepth / _FoamFade), _FoamFadePow) - step(waterVSDepth, _FoamHeadWidth);
		half foam = smoothstep(foamCutoff, foamCutoff + _FoamBlur, foamNoise) * waveAlpha;

		half colorFade = saturate(waterVSDepth / _DepthFade);
		half alphaFade = saturate(waterVSDepth / _AlphaFade);
		colorFade = pow(colorFade, 0.5 * fixViewAngle);
		alphaFade = pow(alphaFade, 0.5 * fixViewAngle);

		// second wave change the foam
		half waveAlphaFactor = 0;
		#ifdef TWO_WAVE
		half waveAlpha2 = frac(waveOffset * 0.5 / PI);
		half waterDepthOffset2 = foamNoise * _FoamWave + _WaveLoopPower + waveNoise * _Wave2LoopRandom * (1 - waveAlpha2) + _Wave2LoopPower * PI * (1 - waveAlpha2);
		half waterVSDepth2 = baseWaterVSDepth - waterDepthOffset2;
		half waveClip2 = smoothstep(waterVSDepth2, waterVSDepth2 + _NearBlur, 0);
		waterVSDepth2 = max(0, waterVSDepth2);

		half foamCutoff2 = pow(saturate(waterVSDepth2 / _FoamFade), _FoamFadePow) - step(waterVSDepth2, _FoamHeadWidth);
		half foam2 = smoothstep(foamCutoff2, foamCutoff2 + _FoamBlur, foamNoise);

		foam  = max(foam, foam2 * (1 - waveClip2) * saturate(waveAlpha2 * _Wave2LoopFadeSpeed));
		waveAlphaFactor = 1 - max(waveAlpha, 1 - waveClip2);
		#endif

		NearAndFoamColorParams result;
		result.colorFade = colorFade;
		result.alphaFade = alphaFade;
		result.foam = foam;
		result.waveAlphaFactor = waveAlphaFactor;
		result.waveClip = waveClip;

		return result;
	}

	half4 frag(v2f i) : SV_Target
	{
		half waterHeight = 1; // TODO:想办法得到或者近似得到水体高度
		// 面板输入水体基础色_WaterColor
		// 根据高度做映射 让水体基础色跟着深度进行渐变 超过一定深度就为1 岸边颜色过渡需要更为明显
		half3 waterColor = _WaterColor.rgb * _WaterColor.a * clamp(waterHeight);
		// 面板输入水底基础色_UnderWaterColor (1)对水底进行混色（该项是水对水底物体的颜色影响）(2)对水体进行混色
		// 根据高度做映射 让基础色跟着深度进行渐变 超过一定深度就为1 岸边颜色过渡需要更为明显
		half3 underWaterColor = _UnderWaterColor.rgb * _UnderWaterColor * (clamp(waterHeight));
		// 面板输入水底基础色和水体基础色的混合控制参数
		// TODO:水体和framebuffer的混合因子
		// (1 - _MixFactor)作为水体的基本透明度。这里有待商榷，最终颜色由水色和之前渲染的framebuffer的输出颜色进行AlphaBlend，
		// underWaterColor 的本意是对framebuffer的输出色进行混色，
		// 但实际过程 underWaterColor 需要通过和水色进行插值混合，然后通过 AlphaBlend 最终影响framebuffer的输出色
		half4 baseColor = (lerp(waterColor, underWaterColor, _MixFactor), 1 - _MixFactor);

		




		Light mainLight = GetMainLight(i.shadowCoord, i.worldPos);

		// geometric info 
		half2 screenUV = i.screenUV.xy / i.screenUV.w;

		DepthInfo depthInfo = GetDepthInfo(i.viewDepth, screenUV, i.worldPos.xyz);

		half3 viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

		half2 waveScale = saturate(_WaveScale.zw);
		half3 horizonOffset = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV.xy));
		half3 verticalOffset = UnpackNormal(SAMPLE_TEXTURE2D(_BumpMap, sampler_BumpMap, i.bumpUV.zw));
		half3 offset = lerp(horizonOffset, verticalOffset, waveScale.x);
		offset.xy = offset.xy * waveScale.y;
		half3 normal = normalize(offset);

		// vertexDepth:0----BlurStart----BlurEnd----Infinity
		// farBlur:    1--------1-----------0----------0
		half farBlur = 1 - saturate((depthInfo.vertexViewDepth - _BlurStart) / (_BlurEnd - _BlurStart));

		half fresnel = pow(1.0 - saturate(dot(half3(0, 1, 0), viewDirection)), _WaterClarity);
		// Schlick's approximation Fresnel formula (UE4 Accelerated version) water fresnel const value:0.02
		half3 fresnelVH = normalize(mainLight.direction.xyz + viewDirection) * viewDirection;
		half Fresnel = 0.02 + (1 - 0.02)  * pow(2, (-5.55473 * fresnelVH - 6.98316) * fresnelVH);

		half3 specularDirection = normalize(reflect(viewDirection, normal));

		half viewAngle = 1 - abs(dot(half3(0, 1, 0), viewDirection)); 

		// color = mix(fresnelColor, depthColor, sepcularColor, reflectColor, nearColor, foamColor)
		half3 fresnelColor = SAMPLE_TEXTURE2D(_WaterColor, sampler_WaterColor, half2(fresnel, 0.5)).rgb;

		//half3 depthColor = SAMPLE_TEXTURE2D(_WaterColor, sampler_WaterColor, half2(depthInfo.waterViewDepth, 0.5)).rgb;

		half3 specularColor = GetSpecularColor(mainLight, specularDirection, horizonOffset, verticalOffset);

		half3 skyCubeColor = DecodeHDREnvironment(SAMPLE_TEXTURECUBE(_ReflectionTex, sampler_ReflectionTex, reflect(viewDirection, normal)), _ReflectionTex_HDR).rgb;
		half3 reflectColor = GetReflectColor(screenUV, skyCubeColor, offset, i.worldPos.xyz);

		NearAndFoamColorParams nearAndFoamColorParams = GetNearAndFoamColorParams(i.bumpUV, offset, depthInfo.waterViewDepth, viewAngle);

		// calc color
		half bgAlpha = 1 - i.color.a;
		bgAlpha = lerp(bgAlpha, 1, nearAndFoamColorParams.waveAlphaFactor);
		half3 color = lerp(_NearColor.rgb, fresnelColor, nearAndFoamColorParams.colorFade);
		bgAlpha = lerp(1, bgAlpha, nearAndFoamColorParams.alphaFade);

		color = color * (1 - bgAlpha) * (1 - fresnel * _ReflectionColor.a);
		reflectColor = reflectColor * _ReflectionColor.rgb * (fresnel * _ReflectionColor.a) * (1 - bgAlpha);

		half foam = saturate(nearAndFoamColorParams.foam * _FoamColor.a);
		color = lerp(color, _FarColor.rgb, foam);
		bgAlpha = bgAlpha * (1 - foam);

		color = color * lerp(_FarColor.rgb, 1, farBlur);
		
		#ifdef UNITY_COLORSPACE_GAMMA
		color = FastSRGBToLinear(color);
		#endif

		#if defined(LIGHTPROBE_SH)
		half4 bakeGI = SampleSHVertex(0);
		#else
		half4 bakeGI = _ROCAmbientColor;
		#endif
		half atten = mainLight.distanceAttenuation * mainLight.shadowAttenuation * max(dot(half3(0,1,0), mainLight.direction.xyz),0);
		color = color * (bakeGI.rgb + mainLight.color * atten);

		color += specularColor * (1 - bgAlpha);

		ApplySceneColor(color);
		ApplyCloudMask(color, i.sceneMapCoord.z);

		color += reflectColor;

		APPLY_SCENE_FOG(color, i, _FogFactor);

		color = LinearColorToProcessColor(color);

		color *= 1 - nearAndFoamColorParams.waveClip;
		bgAlpha = lerp(bgAlpha, 1, nearAndFoamColorParams.waveClip);
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
