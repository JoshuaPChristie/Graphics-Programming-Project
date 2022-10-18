Texture2D texture0 : register(t0);
Texture2D normalMap : register(t1);
SamplerState sampler0 : register(s0);

cbuffer MatrixBuffer : register(b0)
{
    matrix worldMatrix;
    matrix viewMatrix;
    matrix projectionMatrix;
    matrix lightViewMatrix[3];
    matrix lightProjectionMatrix[3];
};

struct InputType
{
    float4 position : POSITION;
    float2 tex : TEXCOORD0;
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


OutputType main(InputType input)
{
    OutputType output;

    //Calculate height values from height map
    float4 colour = texture0.SampleLevel(sampler0, float4(input.tex.x, input.tex.y, 0, 0), 0);
    float maxHeight = 30; //By default values are between 0 and 1, need to increase for worthwhile difference
    input.position.y = colour.x * maxHeight;

    // Calculate the position of the vertex against the world, view, and projection matrices.
    output.position = mul(input.position, worldMatrix);
    output.position = mul(output.position, viewMatrix);
    output.position = mul(output.position, projectionMatrix);

    output.worldPosition = mul(input.position, worldMatrix).xyz;

    //Loop or each light
    for (int i = 0; i < 3; i++)
    {
        // Calculate the position of the vertice as viewed by the light source.
        output.lightViewPos[i] = mul(input.position, worldMatrix);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightViewMatrix[i]);
        output.lightViewPos[i] = mul(output.lightViewPos[i], lightProjectionMatrix[i]);
    }

    output.tex = input.tex;

    //Calculate normal values from height map
    colour = normalMap.SampleLevel(sampler0, float4(input.tex.x, input.tex.y, 0, 0), 0);

    //From https://learnopengl.com/Advanced-Lighting/Normal-Mapping
    //Obtain tangent, bitangent and normal of the plane to translate map normal out of tangent space
    float3 planeNormal = normalize(input.normal);
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

    float3x3 TBN = float3x3(tangent, bitangent, planeNormal);

    //From https://www.braynzarsoft.net/viewtutorial/q16390-23-normal-mapping-bump-mapping
    //Change normal map range from [0, 1] to [-1, 1]
    colour = (2.0f * colour) - 1.0f;

    //output.normal = float3(-colour.x, colour.w, -colour.y);
    output.normal = float3(-colour.x, -colour.y, colour.z);
    //output.normal = float3(colour.y, colour.z, colour.w);
    //output.normal *= float3(0, -1, 0);

    output.normal = mul(output.normal, TBN);

    // Calculate the normal vector against the world matrix only and normalise.
    //output.normal = mul(input.normal, (float3x3)worldMatrix);
    output.normal = mul(output.normal, (float3x3)worldMatrix);
    output.normal = normalize(output.normal);

    output.worldPosition = mul(input.position, worldMatrix).xyz;

    return output;
}