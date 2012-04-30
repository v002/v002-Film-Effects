uniform float amount;

// define our rectangular texture samplers 
uniform sampler2DRect tex0;

// define our varying texture coordinates 
varying vec2 texcoord0;
varying vec2 texdim0;

void main (void)
{

	vec4 input0 = texture2DRect(tex0, texcoord0);
	

	vec3 redmatte = vec3(input0.r - ((input0.g + input0.b)/2.0));
	vec3 greenmatte = vec3(input0.g - ((input0.r + input0.b)/2.0));
	vec3 bluematte = vec3(input0.b - ((input0.r + input0.g)/2.0));

//	vec3 redmatte = vec3(input0.r - input0.g/2.0 + input0.b/2.0);
//	vec3 greenmatte = vec3(input0.g - input0.r/2.0 + input0.b/2.0);
//	vec3 bluematte = vec3(input0.b - input0.r/2.0 + input0.g/2.0);

	redmatte = 1.0 - redmatte;
	greenmatte = 1.0 - greenmatte;
	bluematte = 1.0 - bluematte;

	vec3 red =  greenmatte * bluematte * input0.r;
	vec3 green = redmatte * bluematte * input0.g;
	vec3 blue = redmatte * greenmatte * input0.b;

 	vec4 result = vec4(red.r, green.g, blue.b, input0.a);
	
	result = mix(input0, result, amount);
	result.a = input0.a;

	gl_FragColor = result;
}