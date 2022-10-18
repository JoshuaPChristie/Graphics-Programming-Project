// Tessellation pixel shader
// Output colour passed to stage.

Texture2D shaderTexture : register(t0);

SamplerState Sampler  : register(s0);

/*struct InputType
{
	float4 position : SV_POSITION;
	float4 colour : COLOR;
	float3 normal : NORMAL;
};

cbuffer LightBuffer : register(b0)
{
	float4 ambientColour;
	float4 diffuseColour;
	float3 lightPosition;
	float padding;
}*/

cbuffer LightBuffer : register(b0)
{
	float4 ambientColour[3];
	float4 diffuseColour[3];
	float4 lightPosition[3];
	float4 lightDirection[3];
	float4 attenuation[3];
};

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
	float4 lightViewPos[3] : TEXCOORD2;
};




// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 diffuse)
{
	float intensity = saturate(dot(normal, lightDirection));
	float4 colour = saturate(diffuse * intensity);
	return colour;
}

float4 calculatePointLight(float3 position, float3 worldPosition, float3 normal, float4 diffuse, float range, float3 attenuation)
{
	float4 colour;
	float3 lightVector = position - worldPosition;
	float distance = length(lightVector);
	lightVector /= distance;

	if (distance > range)
	{
		colour = (0.f, 0.f, 0.f, 0.f);
		return colour;
	}
	float intensity = saturate(dot(normal, lightVector));
	colour = saturate(diffuse * intensity);
	float finalAttenuation = attenuation.x + (attenuation.y * distance) + (attenuation.z * (distance * distance));
	colour = saturate(colour / finalAttenuation);

	return colour;
}

float4 calculateSpotLight(float3 position, float3 worldPosition, float3 normal, float4 diffuse, float range, float3 attenuation, float cone, float3 lightDirection)
{
	float4 colour;
	float3 lightVector = position - worldPosition;
	float distance = length(lightVector);
	lightVector /= distance;

	if (distance > range)
	{
		colour = (0.f, 0.f, 0.f, 0.f);
		return colour;
	}
	float intensity = saturate(dot(normal, lightVector));
	colour = saturate(diffuse * intensity);
	float finalAttenuation = attenuation.x + (attenuation.y * distance) + (attenuation.z * (distance * distance));
	colour = saturate(colour / finalAttenuation);
	//Calculate falloff from center to edge of pointlight cone (Bryznarsoft.net)
	colour *= saturate(pow(max(dot(lightVector, -lightDirection), 0.0f), cone));

	return colour;
}

float4 main(InputType input) : SV_TARGET
{

	float4 finalColour = float4(0.f, 0.f, 0.f, 1.f);
	float4 lightColour[3];
	float4 textureColour = shaderTexture.Sample(Sampler, input.tex);

	for (int i = 0; i < 3; i++)
	{
		float type = lightPosition[i].w;
		float range = lightDirection[i].w;
		float cone = attenuation[i].w;

		//Calculate lighting according to light type
		switch (type)
		{
		case 1.f:
			lightColour[i] = calculateLighting(float3(-lightDirection[i].xy, -lightDirection[i].z), input.normal, diffuseColour[i]);
			break;
		case 2.f:
			lightColour[i] = calculatePointLight(lightPosition[i].xyz, input.worldPosition, input.normal, diffuseColour[i], range, attenuation[i].xyz);
			break;
		case 3.f:
			lightColour[i] = calculateSpotLight(float3(lightPosition[i].xy, lightPosition[i].z), float3(input.worldPosition.xy, input.worldPosition.z), input.normal, diffuseColour[i], range, attenuation[i].xyz, cone, float3(lightDirection[i].xy, lightDirection[i].z));
			break;
		}
		finalColour += (lightColour[i] / 3);
		finalColour += (ambientColour[i] / 3);
		finalColour.w = 0.0f;
	}

	return saturate(finalColour) * textureColour;


	//float4 lightColour = ambientColour + calculateLighting(lightPosition, input.normal, diffuseColour);

	//return lightColour;
	//return input.colour;
	//return input.colour * lightColour;
}