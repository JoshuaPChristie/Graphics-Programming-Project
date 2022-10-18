Texture2D shaderTexture : register(t0);
Texture2D depthMapTexture[3] : register(t1);

SamplerState diffuseSampler  : register(s0);
SamplerState shadowSampler : register(s1);

cbuffer LightBuffer : register(b0)
{
    float4 ambientColour[3];
    float4 diffuseColour[3];
    float4 lightPosition[3];
    float4 lightDirection[3];
    float4 attenuation[3];
};

struct InputType
{
    float4 position : SV_POSITION;
    float2 tex : TEXCOORD0;
    float3 normal : NORMAL;
    float3 worldPosition : TEXCOORD1;
    float4 lightViewPos[3] : TEXCOORD2;
};

// Calculate lighting intensity based on direction and normal. Combine with light colour.
float4 calculateLighting(float3 lightDirection, float3 normal, float4 diffuse)
{
    float intensity = saturate(dot(normal, lightDirection));
    float4 colour = saturate(diffuse * intensity);
    return colour;
}

float4 calculateSpotLight(float3 position, float3 worldPosition, float3 normal, float4 diffuse, float range, float3 attenuation, float cone, float3 lightDirection)
{
    float4 colour;
    float3 lightVector = position - worldPosition;
    float distance = length(lightVector);
    //lightVector = normalize(lightVector);
    lightVector /= distance;

    if (distance > range)
    {
        colour = (0.f, 0.f, 0.f, 0.f);
        return colour;
    }
    float intensity = saturate(dot(normal, lightVector));
    colour = saturate(diffuse * intensity);
    float finalAttenuation = attenuation.x + (attenuation.y * distance) + (attenuation.z * (distance * distance));
    colour = saturate(colour / finalAttenuation);
    //Calculate falloff from center to edge of pointlight cone (Bryznarsoft.net)
    colour *= saturate(pow(max(dot(lightVector, float3(-lightDirection.x, -lightDirection.y, -lightDirection.z)), 0.0f), cone));
    //colour *= saturate(pow(max(dot(lightVector, float3(lightDirection.x, lightDirection.y, lightDirection.z)), 0.0f), cone));

    return colour;
}

// Is the gemoetry in our shadow map
bool hasDepthData(float2 uv)
{
    if (uv.x < 0.f || uv.x > 1.f || uv.y < 0.f || uv.y > 1.f)
    {
        return false;
    }
    return true;
}

bool isInShadow(Texture2D sMap, float2 uv, float4 lightViewPosition, float bias)
{
    // Sample the shadow map (get depth of geometry)
    float depthValue = sMap.Sample(shadowSampler, uv).r;
    // Calculate the depth from the light.
    float lightDepthValue = lightViewPosition.z / lightViewPosition.w;
    lightDepthValue -= bias;

    // Compare the depth of the shadow map value and the depth of the light to determine whether to shadow or to light this pixel.
    if (lightDepthValue < depthValue)
    {
        return false;
    }
    return true;
}

float2 getProjectiveCoords(float4 lightViewPosition)
{
    // Calculate the projected texture coordinates.
    float2 projTex = lightViewPosition.xy / lightViewPosition.w;
    projTex *= float2(0.5, -0.5);
    projTex += float2(0.5f, 0.5f);
    return projTex;
}

float4 main(InputType input) : SV_TARGET
{
    float shadowMapBias = 0.005f;
    float4 finalColour = float4(0.f, 0.f, 0.f, 1.f);
    float4 lightColour[3];
    float4 textureColour = shaderTexture.Sample(diffuseSampler, input.tex);

    //Loop for each light
    for (int i = 0; i < 3; i++)
    {
        // Calculate the projected texture coordinates.
        float2 pTexCoord = getProjectiveCoords(input.lightViewPos[i]);

        float type = lightPosition[i].w;
        float range = lightDirection[i].w;
        float cone = attenuation[i].w;

        // Shadow test. Is or isn't in shadow
        if (hasDepthData(pTexCoord))
        {
            // Has depth map data
            if (!isInShadow(depthMapTexture[i], pTexCoord, input.lightViewPos[i], shadowMapBias))
            {
                if (type == 1.f)
                {
                    // is NOT in shadow, therefore light
                    lightColour[i] = calculateLighting(-lightDirection[i].xyz, input.normal, diffuseColour[i]);
                }
                else
                {
                    lightColour[i] = calculateSpotLight(lightPosition[i].xyz, input.worldPosition, input.normal, diffuseColour[i], range, attenuation[i].xyz, cone, lightDirection[i].xyz);
                }

                finalColour += lightColour[i];
                finalColour += ambientColour[i];
            }
        }
    }

    //colour = saturate(colour + ambientColour);
    finalColour.w = 1.0f;
    return saturate(finalColour) * textureColour;
}