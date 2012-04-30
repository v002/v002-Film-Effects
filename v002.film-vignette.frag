uniform float vignette;
uniform float vignetteEdge;
uniform float vignetteMix;

// define our rectangular texture samplers 
uniform sampler2DRect tex0;

// define our varying texture coordinates 
varying vec2 texcoord0;
uniform vec2 dim;

//varying vec2 texcoordLUT;
/// functions

// create a black and white oval about the center of our image for our vignette
vec4 vignetteFucntion(vec2 normalizedTexcoord, float vignetteedge, float vignetteMix)
{
	normalizedTexcoord = 2.0 * normalizedTexcoord - 1.0; // - 1.0 to 1.0
	float r = length(normalizedTexcoord);
	vec4 vignette = (vec4(smoothstep(0.0, 1.0, pow(clamp(r - vignetteMix, 0.0, 1.0), 1.0 + vignetteedge * 10.0))));
	return clamp(1.0 - vignette, 0.0, 1.0);
}



void main (void) 
{ 		
	vec2 normcoord = texcoord0/dim;

	// make a vignette around our borders.
	vec4 vignetteResult = vignetteFucntion(normcoord, vignetteEdge, vignetteMix);

	// sharpen via unsharp mask (subtract image from blured image)
	vec4 input0 = texture2DRect(tex0, texcoord0);

	gl_FragColor = mix(input0,vignetteResult * input0, vignette);		
} 
