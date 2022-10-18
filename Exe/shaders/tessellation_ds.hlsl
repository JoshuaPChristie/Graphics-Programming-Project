// Tessellation domain shader
// After tessellation the domain shader processes the all the vertices


cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
	matrix lightViewMatrix[3];
	matrix lightProjectionMatrix[3];
};

cbuffer TimeBuffer : register(b1)
{
	float time;
	float3 padding;
	float4 waves[3];
}

struct ConstantOutputType
{
	float edges[4] : SV_TessFactor;
	float inside[2] : SV_InsideTessFactor;
};

struct InputType
{
	float3 position : POSITION;
	float4 colour : COLOR;
	float3 normal : NORMAL;
};

struct OutputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
	float4 lightViewPos[3] : TEXCOORD2;
};

//---Unity Waves--- (Cat-like Coding)
float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal)
{
	float PI = 3.1415926535;

	//Limit steepness to prevent looping (divide by number of waves)
	float steepness = wave.x / 3;
	float wavelength = wave.y;
	float k = 2 * PI / wavelength;
	float c = sqrt(9.8 / k);
	float2 d = normalize(wave.zw);
	float f = k * (dot(d, p.xz) - c * time);
	float a = steepness / k;

	tangent += float3(
		-d.x * d.x * (steepness * sin(f)),
		d.x * (steepness * cos(f)),
		-d.x * d.y * (steepness * sin(f))
		);
	binormal += float3(
		-d.x * d.y * (steepness * sin(f)),
		d.y * (steepness * cos(f)),
		-d.y * d.y * (steepness * sin(f))
		);
	return float3(
		d.x * (a * cos(f)),
		a * sin(f),
		d.y * (a * cos(f))
		);
}



[domain("quad")]
OutputType main(ConstantOutputType input, float2 uvwCoord : SV_DomainLocation, const OutputPatch<InputType, 4> patch)
{
	float3 vertexPosition;
	OutputType output;

	// Determine the position of the new vertex.
	// Invert the y and Z components of uvwCoord as these coords are generated in UV space and therefore y is positive downward.
	// Alternatively you can set the output topology of the hull shader to cw instead of ccw (or vice versa).
	//vertexPosition = uvwCoord.x * patch[0].position + -uvwCoord.y * patch[1].position + -uvwCoord.z * patch[2].position;

	//For Quad
	//Interpolate between all four control points to find the center
	float3 v1 = lerp(patch[0].position, patch[1].position, uvwCoord.y);
	float3 v2 = lerp(patch[3].position, patch[2].position, uvwCoord.y);
	vertexPosition = lerp(v1, v2, uvwCoord.x);

	//Determine normal for face
	float3 sideHor = patch[2].position.xyz - patch[0].position.xyz;
	float3 sideVert = patch[1].position.xyz - patch[0].position.xyz;
	float3 faceNormal = normalize(cross(sideHor, sideVert));
	output.normal = faceNormal;

	//Multiple Gerstner Waves

	float3 tangent = float3(1, 0, 0);
	float3 binormal = float3(0, 0, 1);
	float3 p = vertexPosition;
	for (int i = 0; i < 3; i++)
	{
		p += GerstnerWave(waves[i], vertexPosition, tangent, binormal);
	}
	float3 normal = normalize(cross(binormal, tangent));
	vertexPosition = p;
	output.normal = normal;




	// Calculate the normal vector against the world matrix only and normalise.
	output.normal = mul(output.normal, (float3x3)worldMatrix);
	output.normal = normalize(output.normal);

	// Calculate the position of the new vertex against the world, view, and projection matrices.
	output.position = mul(float4(vertexPosition, 1.0f), worldMatrix);
	output.position = mul(output.position, viewMatrix);
	output.position = mul(output.position, projectionMatrix);

	//World position
	output.worldPosition = mul(float4(vertexPosition, 1.0f), worldMatrix).xyz;

	//Loop for each light
	for (int i = 0; i < 3; i++)
	{
		// Calculate the position of the vertice as viewed by the light source.
		output.lightViewPos[i] = mul(float4(vertexPosition, 1.0f), worldMatrix);
		output.lightViewPos[i] = mul(output.lightViewPos[i], lightViewMatrix[i]);
		output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjectionMatrix[i]);
	}

	return output;
}
