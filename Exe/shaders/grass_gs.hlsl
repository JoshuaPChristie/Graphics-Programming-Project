// grass_gs
// Geometry shader that generates a triangle for every vertex.

cbuffer MatrixBuffer : register(b0)
{
	matrix worldMatrix;
	matrix viewMatrix;
	matrix projectionMatrix;
	matrix lightView[3];
	matrix lightProjection[3];
};

cbuffer CamBuffer : register(b1)
{
	float3 camPos;
	float padding;
}

struct InputType
{
	/*float4 position : POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;*/

	float4 position : SV_POSITION;
	float4 colour : COLOR;
	float3 normal : NORMAL;
	float3 worldPosition : TEXCOORD1;
	float4 lightViewPos[3] : TEXCOORD2;
};

struct OutputType
{
	float4 position : SV_POSITION;
	float2 tex : TEXCOORD0;
	float3 normal : NORMAL;
	//float4 colour : COLOR;
	float3 worldPosition : TEXCOORD1;
	float4 lightViewPos[3] : TEXCOORD2;
};

[maxvertexcount(4)]
void main(point InputType input[1], inout TriangleStream<OutputType> triStream)
{
	OutputType output;

	//For billboarding
	float3 worldPosition = mul(input[0].position, worldMatrix).xyz;

	if (input[0].position.y > 4.2)
	{
		//Get vector from camera to billboard, y is fixed so billboard won't tilt up or down
		float3 planeNormal = worldPosition - camPos;
		//float3 planeNormal = input[0].worldPosition - camPos;
		//float3 planeNormal = input[0].position.xyz - camPos;
		planeNormal.y = 0.0f;
		planeNormal = normalize(planeNormal);

		//Aquire up and right vectors from planeNormal and normalize
		float3 upVector = float3(0.0f, 1.0f, 0.0f);
		float3 rightVector = normalize(cross(planeNormal, upVector));

		//Scale vectors to half the size of the billboard
		rightVector = rightVector * 0.25f;
		upVector = upVector * 0.25f;

		// We get the points by using the billboard right vector and up vector
		float3 vert[4];
		/*vert[0] = worldPosition + rightVector + upVector; // Get top left vertex
		vert[1] = worldPosition + rightVector - upVector; // Get bottom left vertex
		vert[2] = worldPosition - rightVector + upVector; // Get top right vertex
		vert[3] = worldPosition - rightVector - upVector; // Get bottom right vertex*/
		vert[0] = input[0].position.xyz + rightVector + upVector; // Get top left vertex
		vert[1] = input[0].position.xyz + rightVector - upVector; // Get bottom left vertex
		vert[2] = input[0].position.xyz - rightVector + upVector; // Get top right vertex
		vert[3] = input[0].position.xyz - rightVector - upVector; // Get bottom right vertex

		// Get billboard texture coordinates
		float2 texCoord[4];
		texCoord[0] = float2(0, 0);
		texCoord[1] = float2(0, 1);
		texCoord[2] = float2(1, 0);
		texCoord[3] = float2(1, 1);

		//output.colour = input[0].colour;

		//Fill out tristream using vrts and coords
		for (int i = 0; i < 4; i++)
		{
			output.position = mul(float4(vert[i], 1.0f), worldMatrix);
			output.position = mul(output.position, viewMatrix);
			output.position = mul(output.position, projectionMatrix);
			//output.position = float4(vert[i], 1.0f);
			output.tex = texCoord[i];

			// This will not be used for billboards
			//output.normal = float3(0, 1, 0);
			output.normal = input[0].normal;

			output.worldPosition = worldPosition;
			//output.worldPosition = input[0].worldPosition;
			//output.worldPosition = mul(input[0].position, worldMatrix).xyz;
			for (int i = 0; i < 3; i++)
			{
				//output.lightViewPos[i] = input[0].lightViewPos[i];
				//output.lightViewPos[i] = input[0].lightViewPos[i]; //+ float4(-0.5f, -0.25f, -0.25f, 0.f);
				output.lightViewPos[i] = mul(input[0].position, worldMatrix);
				output.lightViewPos[i] = mul(output.lightViewPos[i], lightView[i]);
				output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjection[i]);
			}

			triStream.Append(output);
		}

		triStream.RestartStrip();
	}
}

