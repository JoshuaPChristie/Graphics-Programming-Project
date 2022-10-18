// Texture pixel/fragment shader
// Basic fragment shader for rendering textured geometry

// Texture and sampler registers
Texture2D texture0 : register(t0);
Texture2D texture1 : register(t1);
SamplerState Sampler0 : register(s0);

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
};

cbuffer BoolBuffer : register(b0)
{
	bool blend;
	float3 padding;
}

float4 main(InputType input) : SV_TARGET
{
	if (blend)
	{
		return texture0.Sample(Sampler0, input.tex) + texture1.Sample(Sampler0, input.tex);
	}
	else
	{
		// Sample the pixel color from the texture using the sampler at this texture coordinate location.
		return texture0.Sample(Sampler0, input.tex);
	}
}