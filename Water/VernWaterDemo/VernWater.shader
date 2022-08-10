/*
*      Author: Vern LH
*      Version: 2022.6.27
*/

Shader "WaterVernEdition" {
	Properties {
		_DepthFade("岸边宽度", range(0.01, 30)) = 1
		_DepthMax("深水区域深度（超过该值即为深水区域）", range(0.1, 20)) = 1

		[Space]
		[HDR]_WaterColor("水体基础色", COLOR) = (0, 0, 0, 0)
		[HDR]_UnderWaterColor("水底基础色", COLOR) = (0, 0, 0, 0)

		[Space]
		[Normal]_HighFrequencyNormalTex("高频法线纹理", 2D) = "bump" {}
		_HFNormal0TexPanner("高频法线1水流速度(x,y) 和 水流方向(z, w)", Vector) = (0, 0, 0, 0)
		_HFNormal1TexPanner("高频法线2水流速度(x,y) 和 水流方向(z, w)", Vector) = (0, 0, 0, 0)
		[Normal]_LowFrequencyNormalTex("低频法线纹理", 2D) = "bump" {}
		_LFNormalTexPanner("低频法线水流速度(x,y) 和 水流方向(z, w)", Vector) = (0, 0, 0, 0)

		[Space]
		[HDR]_SpecularColor("高光基础色", COLOR) = (0, 0, 0, 0)
		_DirSpecularIntensity("直接高光强度", range(0, 3)) = 1
		_DirSpecularRoughness("直接高光范围（粗糙度）", range(0, 1)) = 0.5
		_EnvSpecularIntensity("环境高光强度", range(0, 3)) = 1
		_EnvSpecularRoughness("环境高光范围（粗糙度）", range(0, 1)) = 0.5

		[Space]
		_Refraction("折射率", range(1, 2)) = 1
		_SSPRDistort("SSPR扭曲", Range(0, 2)) = 1
		[HDR]_SSPRColor("SSPR预乘色", COLOR) = (1, 1, 1, 1)
		_MirrorReflectionDistort("MirrorReflection扭曲", Range(0, 2)) = 1
		[HDR]_MirrorReflectionColor("MirrorReflection预乘色", COLOR) = (1, 1, 1, 1)

		[Space]
		_SkyBoxTex("天空盒", CUBE) = "" {}
		_SkyBoxDistort("天空盒反射扭曲", Range(0, 2)) = 1
		[HDR]_SkyBoxColor("天空盒反射预乘色", Color) = (1,1,1,1)

		[Space]
		_FoamTex ("泡沫纹理", 2D) = "black" {}
		[HDR]_FoamColor("泡沫颜色", color) = (1, 1, 1, 1)
		_FoamFade("泡沫宽度", range(0,5)) = 1
		_FoamFadePow("边缘泡沫增强", range(0,2)) = 1.25
		_FoamHeadWidth("边缘白边宽度", range(0,1)) = 0.2
		_FoamBlur("泡沫软边", Range(0.01,1)) = 0.01

		[Space]
		_WaveRandomMap("水面起伏噪波", 2D) = "black" {}
		_WaveLoopPower("水面起伏强度", range(0, 2)) = 0.5
		_WaveLoopRandom("水面起伏随机强度", range(0, 1)) = 1
		_WaveLoopSpeed("水面起伏速度", range(0, 4)) = 1
	}

	HLSLINCLUDE
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SoftColorSpaceLinear.hlsl"

	CBUFFER_START(UnityPerMaterial)
	half _DepthFade;
	half _DepthMax;

	half4 _WaterColor;
	half4 _UnderWaterColor;

	TEXTURE2D(_HighFrequencyNormalTex); SAMPLER(sampler_HighFrequencyNormalTex); half4 _HighFrequencyNormalTex_ST;
	half4 _HFNormal0TexPanner;
	half4 _HFNormal1TexPanner;
	TEXTURE2D(_LowFrequencyNormalTex); SAMPLER(sampler_LowFrequencyNormalTex); half4 _LowFrequencyNormalTex_ST;
	half4 _LFNormalTexPanner;

	half4 _SpecularColor;
	half _DirSpecularIntensity;
	half _DirSpecularRoughness;
	half _EnvSpecularIntensity;
	half _EnvSpecularRoughness;

	half _Refraction;
	half _SSPRDistort;
	half4 _SSPRColor;
	half _MirrorReflectionDistort;
	half4 _MirrorReflectionColor;

	TEXTURECUBE(_SkyBoxTex); SAMPLER(sampler_SkyBoxTex);
	half4 _SkyBoxTex_HDR;
	half _SkyBoxDistort;
	half4 _SkyBoxColor;

	TEXTURE2D(_MirrorReflectionTex); SAMPLER(sampler_MirrorReflectionTex);

	TEXTURE2D(_FoamTex); SAMPLER(sampler_FoamTex);
	half4 _FoamColor;
	half _FoamFade;
	half _FoamFadePow;
	half _FoamHeadWidth;
	half _FoamBlur;

	TEXTURE2D(_WaveRandomMap); SAMPLER(sampler_WaveRandomMap); half4 _WaveRandomMap_ST;
	half _WaveLoopPower;
	half _WaveLoopSpeed;
	half _WaveLoopRandom;

	TEXTURE2D(_CameraOpaqueTexture); SAMPLER(sampler_CameraOpaqueTexture);
	TEXTURE2D(_CameraDepthTexture); SAMPLER(sampler_point_clamp);
	CBUFFER_END

	half4 _SunColor;
	half4 _AmbientColor;

	struct appdata
	{
		float3 position : POSITION;
	    half4 color : COLOR;
	};

	struct v2f
	{
		float4 position : SV_POSITION;
		float4 worldPos : TEXCOORD0;
	    float viewDepth : TEXCOORD1;
	    half4 color : COLOR;
		float4 screenUV : TEXCOORD2;
		float4 shadowCoord : TEXCOORD3;
	};

	v2f vert(appdata v)
	{
		v2f o;
	    o.color = v.color;
		o.worldPos = mul(GetObjectToWorldMatrix(), float4(v.position, 1));
	    o.viewDepth = -mul(GetWorldToViewMatrix(), o.worldPos).z;

	    o.position = TransformObjectToHClip(v.position.xyz);
		o.screenUV = ComputeScreenPos(o.position);

		VertexPositionInputs vertexInput = GetVertexPositionInputs(v.position.xyz);
		o.shadowCoord = GetShadowCoord(vertexInput);

		return o;
	}

	half GetWaterDepth(half pixelDepth, half2 screenUV, half3 worldPos)
	{
		// 相似三角形算当前着色点水面的近似深度
		float screenDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_point_clamp, screenUV);
		screenDepth = LinearEyeDepth(screenDepth, _ZBufferParams);
		half waterViewDepth = abs(screenDepth - pixelDepth);
		half waterCameraDistance = distance(_WorldSpaceCameraPos.xyz, worldPos.xyz);
		half waterCameraXZDistance = abs(_WorldSpaceCameraPos.y - worldPos.y);
		return waterCameraXZDistance * waterViewDepth / waterCameraDistance;
	}

	float3 UE_CookTorranceBRDF(float NoV, float NoL, float NoH, float VoH, float roughness, float3 specularColor)
	{
		float roughness2 = roughness * roughness;
		float roughness4 = roughness2 * roughness2;

		NoV = saturate(abs(NoV) + 1e-5);

		float D = (NoH * roughness4 - NoH) * NoH + 1;
		D = roughness4 / (PI * D * D);

		float V_SimthV = NoL * (NoV * (1 - roughness2) + roughness2);
		float V_SimthL = NoV * (NoL * (1 - roughness2) + roughness2);
		float Vis = 0.5 * rcp(V_SimthV + V_SimthL);

		float Fc = pow(1 - VoH, 5);
		float3 F = Fc + (1 - Fc) * specularColor;

		float3 directlightSpec = (D * Vis) * F;
		return directlightSpec;
	}

	float3 UE_SampleBRDF(float3 N, float3 V, float3 L, float roughness4, float3 specularColor)
	{
		float NoV = saturate(dot(N, V));
		float3 H = normalize(V + L);
		float NoH = saturate(dot(N, H));

		float D = (NoH * roughness4 - NoH) * NoH + 1;
		D = roughness4 / (PI * D * D);

		float Vis = 0.25;

		float3 F = specularColor;
		return D * Vis * F;
	}

	half3 WaterNormalT2W(half3 normal)
	{
		half3x3 T2WMatrix = half3x3(1, 0, 0, 0, 0, -1, 0, 1, 0);
		half3 result = TransformTangentToWorld(normal, T2WMatrix);
		return result;
	}

	float Fresnel(float F0, float Exponent, float VoH)
	{
		float base = max(0, VoH);
		base = abs(1 - base);
		base = max(0.0001, base);
		return F0 + (1 - F0) * pow(base, Exponent);
	}

	float2 RefractionUVOffset(half3 N, half depthFade)
	{
		half3 ViewNormal = mul(GetWorldToViewMatrix(), N);
		half3 ViewVertexNormal = mul(GetWorldToViewMatrix(), half3(0, 1, 0));
		float2 DistortionUV = (ViewVertexNormal.xz - ViewNormal.xz) * (lerp(1, _Refraction, depthFade) - 1);
		float InvTanHalfFov = UNITY_MATRIX_P[0].x;
		float Ratio = _ScreenParams.x / _ScreenParams.y;
		float2 FovFix = float2(InvTanHalfFov, Ratio * InvTanHalfFov);
		DistortionUV = DistortionUV * (_ScreenParams.xy * float2(0.00023, -0.00023) * FovFix);
		return DistortionUV;
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
		float depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_point_clamp, uv);
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
		half2 screenUV = i.screenUV.xy / i.screenUV.w;
		Light mainLight = GetMainLight(i.shadowCoord, i.worldPos);

		// 高频法线
		half2 highFrequencyUV0 = (i.worldPos.xz + _HFNormal0TexPanner.xy * _Time.xx) * _HFNormal0TexPanner.zw;
		half2 highFrequencyUV1 = (i.worldPos.xz + _HFNormal1TexPanner.xy * _Time.xx) * _HFNormal1TexPanner.zw;
		half3 highFrequencyNormal0 = UnpackNormal(SAMPLE_TEXTURE2D(_HighFrequencyNormalTex, sampler_HighFrequencyNormalTex, highFrequencyUV0)).xyz;
		half3 highFrequencyNormal1 = UnpackNormal(SAMPLE_TEXTURE2D(_HighFrequencyNormalTex, sampler_HighFrequencyNormalTex, highFrequencyUV1)).xyz;
		// 低频法线
		half2 lowFrequencyUV = (i.worldPos.xz + _LFNormalTexPanner.xy * _Time.xx) * _LFNormalTexPanner.zw;
		half3 lowFrequencyNormal = UnpackNormal(SAMPLE_TEXTURE2D(_LowFrequencyNormalTex, sampler_LowFrequencyNormalTex, lowFrequencyUV)).xyz;
		half3 N = (highFrequencyNormal0 + highFrequencyNormal1) + lowFrequencyNormal;

		N = normalize(WaterNormalT2W(N));
		half3 L = mainLight.direction.xyz;
		half3 V = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
		float NoL = dot(N, L);
		NoL = saturate(NoL);
		half3 H = normalize(V + L);
		float NoV = dot(N, V);
		float VoL = dot(V, L);
		float InvLenH = rsqrt(2 + 2 * VoL);
		float NoH = saturate((NoL + NoV) * InvLenH);
		float VoH = saturate(InvLenH + InvLenH * VoL);

		// wave: fake water height 
		half perlinNoise = SAMPLE_TEXTURE2D(_WaveRandomMap, sampler_WaveRandomMap, N.xz * _WaveRandomMap_ST.xy + _WaveRandomMap_ST.zw).r;
		half waveTime = _Time.y * _WaveLoopSpeed + perlinNoise * PI * 2 * _WaveLoopRandom;
		half depthOffset = perlinNoise * 0.01 + _WaveLoopPower * (sin(waveTime) * 0.5 + 0.5);

		half waterHeight = GetWaterDepth(i.viewDepth, screenUV, i.worldPos.xyz);
		waterHeight = saturate(waterHeight - depthOffset);
		float fresnel = Fresnel(0.04, 5, NoV);
		half waterHeightFactor = waterHeight / _DepthMax;
		half depthFade = saturate(waterHeight / _DepthFade);
		half opacity = saturate(pow(waterHeightFactor, 0.2) + fresnel) * depthFade;
		half colorMixFactor = saturate(pow(waterHeightFactor, 0.6));

		half3 waterColor = _WaterColor.rgb * _WaterColor.a;
		half3 underWaterColor = _UnderWaterColor.rgb * _UnderWaterColor.a;
		half3 baseColor = lerp(underWaterColor, waterColor, colorMixFactor);

		float specular = 0.04;
		half3 specularColor = _SpecularColor.rgb * _SpecularColor.a;
		half3 dirSpecularColor = _DirSpecularIntensity * specular * UE_CookTorranceBRDF(NoV, NoL, NoH, VoH, _DirSpecularRoughness, specularColor);

		// 给水面一个假的光照，来模拟非直接光产生的高光
		// UNITY_MATRIX_V[0] = camera's RightUnitVector in world space
		// UNITY_MATRIX_V[1] = camera's UpUnitVector in world space
		// UNITY_MATRIX_V[2] = camera's ForwardUnitVector in world space
		half3 cameraLookAt = UNITY_MATRIX_V[2].xyz;
		half3 envLightDirection = reflect(-cameraLookAt, half3(0, 1, 0));
		half3 envSpecularColor = _EnvSpecularIntensity * specular * UE_SampleBRDF(N, V, envLightDirection, pow(_EnvSpecularRoughness, 4), specularColor);

		half4 ambientColor;
		#if defined(LIGHTPROBE_SH)
		ambientColor = SampleSHVertex(0);
		#else
		ambientColor = _AmbientColor;
		#endif

		// 太阳光是什么 点光源？ 这里是否对颜色有贡献 是否需要走cook-torrance模型
		//half3 sunColor = _SunColor.rgb * _SunColor.a;
		half atten = mainLight.distanceAttenuation * mainLight.shadowAttenuation * max(NoL,0);
		half3 mainLightColor = mainLight.color * atten;
		half3 color = (baseColor.rgb + dirSpecularColor + envSpecularColor) * mainLightColor + baseColor  * ambientColor;

		half3 skyBoxNormal = normalize(half3(N.x * _SkyBoxDistort, 1, N.z * _SkyBoxDistort));
		half3 skyColor = DecodeHDREnvironment(SAMPLE_TEXTURECUBE(_SkyBoxTex, sampler_SkyBoxTex, reflect(-V, skyBoxNormal)), _SkyBoxTex_HDR).rgb;
		skyColor = skyColor * _SkyBoxColor.rgb * _SkyBoxColor.a;

		// SSPR / MirrorReflection + Skybox
		half3 reflectColor = skyColor;
		// SSPR
		half3 rayOrigin = TransformWorldToViewDir(i.worldPos.xyz - _WorldSpaceCameraPos.xyz);
		half3 SSPRNormal = normalize(half3(N.x * _SSPRDistort, 1, N.z * _SSPRDistort));
		half3 viewSpaceNormal = TransformWorldToViewDir(SSPRNormal);
		half3 reflectionDir = normalize(reflect(rayOrigin, viewSpaceNormal));
		half2 hitUV = 0;
		if (RayMarching(rayOrigin, reflectionDir, hitUV))
		{
			reflectColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, hitUV).xyz;
			reflectColor = reflectColor * _SSPRColor.rgb * _SSPRColor.a;
		}
		color = color / 2 + color * reflectColor + reflectColor;

		// Foam
		half foamAlpha = SAMPLE_TEXTURE2D(_FoamTex, sampler_FoamTex, N.xz).r;
		// step(a, b) = return a <= b ? 1 : 0;if a < b return 0 else return 1
		// smoothstep(min, max, x) return 0 if x < min; return 1 if x > max; return nonlinearlerp(0, 1, (x - min) / (max - min)) if min < x < max
		half foamFade = waterHeight / _FoamFade;
		half foam_cutoff = pow(saturate(foamFade), _FoamFadePow) - step(foamFade, _FoamHeadWidth);
		half foamFactor = smoothstep(foam_cutoff, foam_cutoff + _FoamBlur, foamAlpha);
		foamFactor = saturate(foamFactor * _FoamColor.a);
		color = lerp(color, _FoamColor.rgb, foamFactor);
		opacity = 1 - (1 - opacity) * (1 - foamFactor);

		// Refraction
		float2 refractionUVOffset = RefractionUVOffset(N, depthFade);
		float2 DistortUV = screenUV + refractionUVOffset * saturate(waterHeight);
		half3 DistortOpaqueColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, DistortUV);

		opacity = opacity * step(0.001, waterHeight);
		color = color * opacity + DistortOpaqueColor.xyz * (1 - opacity);

		color = LinearColorToProcessColor(color);

		return half4(color, 1);
	}
	ENDHLSL

	Subshader {
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 400

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One Zero
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			#pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}

	Subshader {
		Tags { "RenderType"="Transparent" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 300

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One Zero
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			#pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}

	Subshader {
		Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline" "IgnoreProjector" = "True" "Queue" = "Transparent-10" }
		LOD 100

		Pass {
			Tags{ "LightMode" = "UniversalForward" }
			Blend One Zero
			ZTest LEqual ZWrite Off Cull Back

			HLSLPROGRAM
			#pragma enable_d3d11_debug_symbols
			#pragma vertex vert
			#pragma fragment frag
			ENDHLSL
		}
	}
	Fallback Off
}
