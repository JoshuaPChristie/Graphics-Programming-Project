Texture2D shaderTexture : register(t0);
SamplerState SampleType : register(s0);

cbuffer ScreenSizeBuffer : register(b0)
{
    float screenHeight;
    float3 padding;
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;  
};

float4 main(InputType input) : SV_TARGET
{
    //float weight0, weight1, weight2, weight3, weight4;
    float4 colour;

	// Create the weights that each neighbor pixel will contribute to the blur.
	//Two Neightbours
	/*weight0 = 0.4062f;
    weight1 = 0.2442f;
    weight2 = 0.0545f;*/
	//Four Neighbours
	/*weight0 = 0.382928;
	weight1 = 0.241732;
	weight2 = 0.060598;
	weight3 = 0.005977;
	weight4 = 0.000229;*/
	//Five Neighbours
	float weight[5] = { 0.227027, 0.1945946, 0.1216216, 0.054054, 0.016216 };

	// Initialize the colour to black.
    colour = float4(0.0f, 0.0f, 0.0f, 0.0f);

    float texelSize = 1.0f / screenHeight;
    // Add the horizontal pixels to the colour by the specific weight of each.
	//Five Neighbours
    for (int i = 0; i < 5; ++i)
    {
        colour += shaderTexture.Sample(SampleType, input.tex + float2(0.0f, texelSize * i)) * weight[i];
        colour += shaderTexture.Sample(SampleType, input.tex - float2(0.0f, texelSize * i)) * weight[i];
    }
 
    // Set the alpha channel to one.
    colour.a = 1.0f;

    return colour;
}

