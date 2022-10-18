// Tessellation Hull Shader
// Prepares control points for tessellation
cbuffer FactorBuffer : register(b0)
{
	float4 edgeFactor;
	float2 inFactor;
	float2 padding;
}

struct InputType
{
	float3 position : POSITION;
	float2 tex : TEXCOORD0;
	float4 colour : COLOR;
};

struct ConstantOutputType
{

	float edges[3] : SV_TessFactor;
	float inside[1] : SV_InsideTessFactor;
};

struct OutputType
{
	float3 position : POSITION;
	float2 tex : TEXCOORD0;
	float4 colour : COLOR;
};

ConstantOutputType PatchConstantFunction(InputPatch<InputType, 3> inputPatch, uint patchId : SV_PrimitiveID)
{
	ConstantOutputType output;


	// Set the tessellation factors for the three edges of the triangle.
	output.edges[0] = edgeFactor.x;
	output.edges[1] = edgeFactor.x;
	output.edges[2] = edgeFactor.x;

	// Set the tessellation factor for tessallating inside the triangle.
	output.inside[0] = edgeFactor.x;

	return output;
}

[domain("tri")]
[partitioning("integer")]
[outputtopology("triangle_cw")]
[outputcontrolpoints(3)]
[patchconstantfunc("PatchConstantFunction")]
OutputType main(InputPatch<InputType, 3> patch, uint pointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
	OutputType output;


	// Set the position for this control point as the output position.
	output.position = patch[pointId].position;

	output.tex = patch[pointId].tex;

	// Set the input colour as the output colour.
	output.colour = patch[pointId].colour;

	return output;
}