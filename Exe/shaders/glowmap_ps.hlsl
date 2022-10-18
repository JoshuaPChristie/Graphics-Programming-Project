// Glowmap pixel/fragment shader
// Basic fragment shader for rendering glowmaps

// Texture and sampler registers
Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};


float4 main(InputType input) : SV_TARGET
{
	//float4 colour;

	// Sample the pixel color from the texture using the sampler at this texture coordinate location.
	float4 colour = texture0.Sample(Sampler0, input.tex);

	//float brightness = dot(colour.xyz, float3(0.2126, 0.7152, 0.0722));
	//if (brightness > 1.0)
	if (colour.r > 1.7 || colour.g > 1.7 || colour.b > 1.7)
	{
		return colour;
	}
	else
	{
		return float4(0.0, 0.0, 0.0, 1.0);
	}
}