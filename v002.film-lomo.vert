
varying vec2 texcoord0;
varying vec2 texcoord1;
varying vec2 texcoord2;
varying vec2 texcoord3;
varying vec2 texcoord4;
varying vec2 texdim0;
varying vec2 texdim1;

//varying vec2 texcoordLUT;

uniform vec2 dim;
uniform vec2 dim2;
uniform float sharpness;

void main()
{
    // perform standard transform on vertex
    gl_Position = ftransform();

    // transform texcoords
    texcoord0 = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
//    texcoordLUT = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);

    // extract the x and y scalars from the texture matrix to determine dimensions
	// texdim0 = vec2 (abs(gl_TextureMatrix[0][0][0]),abs(gl_TextureMatrix[0][1][1]));
	texdim0 = dim;
	texdim1 = dim2;
	
	vec2 zero = vec2(0.0);

	texcoord1 = clamp(texcoord0 + vec2(-sharpness, -sharpness), zero, texdim0);
	texcoord2 = clamp(texcoord0 + vec2(+sharpness, -sharpness), zero, texdim0);
	texcoord3 = clamp(texcoord0 + vec2(+sharpness, +sharpness), zero, texdim0);
	texcoord4 = clamp(texcoord0 + vec2(-sharpness, +sharpness), zero, texdim0);

}