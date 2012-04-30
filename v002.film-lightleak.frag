uniform float amount;
uniform float length;

// define our rectangular texture samplers 
uniform sampler2DRect tex0;
uniform sampler2DRect tex1; // for LUT

// define our varying texture coordinates 
varying vec2 texcoord0;
// rotation matrix
varying mat2 rotmat;

uniform vec2 texdim0;
uniform vec2 texdim1;

void main (void) 
{ 		
	// our normal image.
	vec4 input0 = texture2DRect(tex0, texcoord0);

	// normalized point 0 - 1 texcoords
	vec2 point = texcoord0/texdim0;
	
	// rotate sampling point
	point = ((point - 0.5) * rotmat) + 0.5;
	point = clamp(point, 0.0, 1.0);

	// this adjusts the length of the leak
	float leakIntensity = pow(point.y, 1.0 + ((1.0 - length) * 19.0));

	// this adjusts the gamma/brightness of the overall effect.
	leakIntensity =  pow(leakIntensity, 1.0 / amount);

	// sample the leak // how do we want to hanle edge texcoords during rotation? 
	//vec4 leak = texture2DRect(tex1, mod(vec2(point.x, 0.0), 1.0) * texdim1);
	point = mod(point, 1.0);
	vec4 leak = texture2DRect(tex1, vec2(point.x, 0.0) * texdim1);

	leak = pow(leak * leakIntensity, vec4(1.0/(leakIntensity))); // - vec2(0.5, 0.0);
	leak += input0;

	gl_FragColor = mix(input0, leak, amount);
} 
