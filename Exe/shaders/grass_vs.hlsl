// Grass vertex shader.
// Doesn't do much, could manipulate the control points
// Pass forward data, strip out some values not required for example.
Texture2D texture0 : register(t0);
SamplerState sampler0 : register(s0);

struct InputType
{
	float3 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
};

struct OutputType
{
	float3 position : POSITION;
	float2 tex : TEXCOORD0;
	float4 colour : COLOR;
};

OutputType main(InputType input)
{
	OutputType output;

	//Calculate height values from height map
	//float4 colour = texture0.SampleLevel(sampler0, float4(input.tex.x, input.tex.y, 0, 0), 0);
	//float maxHeight = 30; //By default values are between 0 and 1, need to increase for worthwhile difference
	//input.position.y = colour.x * maxHeight;

	// Pass the vertex position into the hull shader.
	output.position = input.position;

	output.tex = input.tex;

	// Pass the input color into the hull shader.
	output.colour = float4(1.0, 0.0, 0.0, 1.0);
	//output.colour = colour;

	return output;
}
