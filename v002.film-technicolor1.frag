uniform float amount;

// define our rectangular texture samplers 
uniform sampler2DRect tex0;

// define our varying texture coordinates 
varying vec2 texcoord0;
varying vec2 texdim0;

const vec4 redfilter 		= vec4(1.0, 0.0, 0.0, 1.0);
const vec4 bluegreenfilter 	= vec4(0.0, 1.0, 0.7, 1.0);


void main(void)
{
	
	vec4 input0 = texture2DRect(tex0, texcoord0);

	vec4 redrecord = input0 * redfilter;
	vec4 bluegreenrecord = input0 * bluegreenfilter;
	
	vec4 rednegative = vec4(redrecord.r);
	vec4 bluegreennegative = vec4((bluegreenrecord.g + bluegreenrecord.b)/2.0);

	vec4 redoutput = rednegative * redfilter;
	vec4 bluegreenoutput = bluegreennegative * bluegreenfilter;

	// additive 'projection"
	vec4 result = redoutput + bluegreenoutput;
	
	result = mix(input0, result, amount);
	result.a = input0.a;

	gl_FragColor = result;
}