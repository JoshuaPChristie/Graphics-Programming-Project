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
	float4 colour : COLOR;
	float3 normal : NORMAL;
};

struct ConstantOutputType
{
	float edges[4] : SV_TessFactor;
	float inside[2] : SV_InsideTessFactor;
};

struct OutputType
{
	float3 position : POSITION;
	float4 colour : COLOR;
	float3 normal : NORMAL;
};

ConstantOutputType PatchConstantFunction(InputPatch<InputType, 4> inputPatch, uint patchId : SV_PrimitiveID)
{
	ConstantOutputType output;


	// Set the tessellation factors for the three edges of the triangle.
	/*output.edges[0] = 3;
	output.edges[1] = 3;
	output.edges[2] = 3;*/

	output.edges[0] = edgeFactor.x;
	output.edges[1] = edgeFactor.y;
	output.edges[2] = edgeFactor.z;
	output.edges[3] = edgeFactor.w;

	// Set the tessellation factor for tessallating inside the triangle.
	//output.inside = 3;
	output.inside[0] = inFactor.x;
	output.inside[1] = inFactor.y;

	return output;
}


[domain("quad")]
[partitioning("integer")]
[outputtopology("triangle_ccw")]
[outputcontrolpoints(4)]
[patchconstantfunc("PatchConstantFunction")]
OutputType main(InputPatch<InputType, 4> patch, uint pointId : SV_OutputControlPointID, uint patchId : SV_PrimitiveID)
{
	OutputType output;


	// Set the position for this control point as the output position.
	output.position = patch[pointId].position;

	// Set the input colour as the output colour.
	output.colour = patch[pointId].colour;

	output.normal = patch[pointId].normal;

	return output;
}