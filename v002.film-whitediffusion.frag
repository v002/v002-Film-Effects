uniform float amount;
uniform float exposure;
uniform float diffusion;

uniform sampler2DRect tex0;

varying vec2 texcoord0;
varying vec2 texcoord1;
varying vec2 texcoord2;
varying vec2 texcoord3;
varying vec2 texcoord4;
varying vec2 texcoord5;
varying vec2 texcoord6;
varying vec2 texcoord7;
varying vec2 texcoord8;

const vec4 lumcoeff = vec4(0.299,0.587,0.114, 0.0);

const float sqrtoftwo = 1.41421356237;

void main(void )
{
	vec4 input0 = texture2DRect(tex0, texcoord0);
	vec4 input1 = texture2DRect(tex0, texcoord1);
	vec4 input2 = texture2DRect(tex0, texcoord2);
	vec4 input3 = texture2DRect(tex0, texcoord3);
	vec4 input4 = texture2DRect(tex0, texcoord4);
	vec4 input5 = texture2DRect(tex0, texcoord5);
	vec4 input6 = texture2DRect(tex0, texcoord6);
	vec4 input7 = texture2DRect(tex0, texcoord7);
	vec4 input8 = texture2DRect(tex0, texcoord8);
	
	vec4 blurresult = (input0 + input1 + input2 + input3 + input4 + input5 + input6 + input7 + input8) * 0.125;

	vec4 origluma = vec4(dot(input0, lumcoeff));
	vec4 luma = vec4(dot(blurresult,lumcoeff));

	vec4 contrast = mix(origluma, luma, diffusion);

	vec4 exposureresult = log2(vec4(pow(exposure + sqrtoftwo, 2.0))) * luma;

	vec4 result = mix(origluma, exposureresult, luma * contrast);
	result = mix(input0, result , amount);
	result.a = input0.a;
	
	gl_FragColor = result;
}
