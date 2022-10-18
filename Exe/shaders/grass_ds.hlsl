// Grass domain shader
// After tessellation the domain shader processes the all the vertices
Texture2D texture0 : register(t0);
Texture2D normalMap : register(t1);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
	matrix lightView[3];
	matrix lightProjection[3];
};

struct ConstantOutputType
{

	float edges[3] : SV_TessFactor;
	float inside[1] : SV_InsideTessFactor;
};

struct InputType
{
	float3 position : POSITION;
	float2 tex : TEXCOORD0;
	float4 colour : COLOR;
};

struct OutputType
{
	float4 position : SV_POSITION;
	float4 colour : COLOR;
	float3 normal : NORMAL;
	//float3 worldPosition : TEXCOORD1;
	//float4 lightViewPos[2] : TEXCOORD2;
};

[domain("tri")]
OutputType main(ConstantOutputType input, float3 uvwCoord : SV_DomainLocation, const OutputPatch<InputType, 3> patch)
{
	float3 vertexPosition;
	float3 vertexNormal;
	OutputType output;

	float3 mapPositions[3];
	float3 mapNormals[3];
	for (int i = 0; i < 3; i++)
	{
		//Calculate height values from height map
		float4 mapColour = texture0.SampleLevel(sampler0, float4(patch[i].tex.x, patch[i].tex.y, 0, 0), 0);
		float maxHeight = 30;
		mapPositions[i] = patch[i].position;
		mapPositions[i].y = mapColour.x * maxHeight;
		//mapPositions[i].y = patch[i].colour.x * maxHeight;

		//Calculate normal values from height map
		mapColour = normalMap.SampleLevel(sampler0, float4(patch[i].tex.x, patch[i].tex.y, 0, 0), 0);

		//From https://www.braynzarsoft.net/viewtutorial/q16390-23-normal-mapping-bump-mapping
		//Change normal map range from [0, 1] to [-1, 1]
		//mapColour = (2.0f * mapColour) - 1.0f;

		//mapNormals[i] = mapColour.xwy;
		//mapPositions[i].y = patch[i].colour.x * maxHeight;

		//From https://learnopengl.com/Advanced-Lighting/Normal-Mapping
		//Obtain tangent, bitangent and normal of the plane to translate map normal out of tangent space
		// positions
		float3 pos1 = float3(-1.0, 0.0, 1.0);
		float3 pos2 = float3(-1.0, 0.0, -1.0);
		float3 pos3 = float3(1.0, 0.0, -1.0);
		// texture coordinates
		float2 uv1 = float2(0.0, 1.0);
		float2 uv2 = float2(0.0, 0.0);
		float2 uv3 = float2(1.0, 0.0);

		float3 edge1 = pos2 - pos1;
		float3 edge2 = pos3 - pos1;
		float2 deltaUV1 = uv2 - uv1;
		float2 deltaUV2 = uv3 - uv1;

		float f = 1.0f / (deltaUV1.x * deltaUV2.y - deltaUV2.x * deltaUV1.y);

		float3 tangent;
		tangent.x = f * (deltaUV2.y * edge1.x - deltaUV1.y * edge2.x);
		tangent.y = f * (deltaUV2.y * edge1.y - deltaUV1.y * edge2.y);
		tangent.z = f * (deltaUV2.y * edge1.z - deltaUV1.y * edge2.z);
		tangent = normalize(tangent);

		float3 bitangent;
		bitangent.x = f * (-deltaUV2.x * edge1.x + deltaUV1.x * edge2.x);
		bitangent.y = f * (-deltaUV2.x * edge1.y + deltaUV1.x * edge2.y);
		bitangent.z = f * (-deltaUV2.x * edge1.z + deltaUV1.x * edge2.z);
		bitangent = normalize(bitangent);

		//normal
		//float3 planeNormal = cross(tangent, bitangent);
		float3 planeNormal = float3(0.f, 1.f, 0.f);

		float3x3 TBN = float3x3(tangent, bitangent, planeNormal);

		//From https://www.braynzarsoft.net/viewtutorial/q16390-23-normal-mapping-bump-mapping
		//Change normal map range from [0, 1] to [-1, 1]
		mapColour = (2.0f * mapColour) - 1.0f;

		//output.normal = float3(-colour.x, colour.w, -colour.y);
		mapNormals[i] = float3(-mapColour.x, -mapColour.y, mapColour.z);
		mapNormals[i] = mul(mapNormals[i], TBN);
	}

	// Determine the position of the new vertex.
	// Invert the y and Z components of uvwCoord as these coords are generated in UV space and therefore y is positive downward.
	// Alternatively you can set the output topology of the hull shader to cw instead of ccw (or vice versa).
	//vertexPosition = uvwCoord.x * patch[0].position + uvwCoord.y * patch[1].position + uvwCoord.z * patch[2].position;
	vertexPosition = (uvwCoord.x * mapPositions[0]) + (uvwCoord.y * mapPositions[1]) + (uvwCoord.z * mapPositions[2]);

	vertexNormal = (uvwCoord.x * mapNormals[0]) + (uvwCoord.y * mapNormals[1]) + (uvwCoord.z * mapNormals[2]);

	/*float4 mapColour = texture0.SampleLevel(sampler0, float4(patch[0].tex.x, patch[0].tex.y, 0, 0), 0);
	float maxHeight = 30;
	vertexPosition.y = mapColour.x * maxHeight;*/

	// Calculate the position of the new vertex against the world, view, and projection matrices.
	output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
	//output.position = mul(output.position, viewMatrix);
	//output.position = mul(output.position, projectionMatrix);

	//World position
	/*output.worldPosition = mul(float4(vertexPosition, 1.0f), worldMatrix).xyz;

	//Loop for each light
	for (int i = 0; i < 2; i++)
	{
		// Calculate the position of the vertice as viewed by the light source.
		output.lightViewPos[i] = mul(float4(vertexPosition, 1.0f), worldMatrix);
		output.lightViewPos[i] = mul(output.lightViewPos[i], lightView[i]);
		output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjection[i]);
	}*/

	// Calculate the normal vector against the world matrix only and normalise.
	output.normal = mul(vertexNormal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	// Send the input color into the pixel shader.
	//output.colour = patch[0].colour;
	//output.colour = float4(1.0, 0.0, 0.0, 1.0);

	return output;

}
