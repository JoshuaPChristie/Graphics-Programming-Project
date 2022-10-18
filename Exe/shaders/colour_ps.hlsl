// Colour pixel/fragment shader
// Basic fragment shader for rendering flat colour geometry

// Texture and sampler registers
Texture2D texture0 : register(t0);
SamplerState Sampler0 : register(s0);

struct InputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

cbuffer ColourBuffer : register(b0)
{
	float4 colour;
};


float4 main(InputType input) : SV_TARGET
{
	return colour;
}