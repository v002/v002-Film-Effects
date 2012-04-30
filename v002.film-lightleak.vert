varying vec2 texcoord0;
varying vec2 texdim0;
varying vec2 texdim1;
varying mat2 rotmat;

uniform float angle;

void main()
{
	// setup basic rotation matrix here
	float theta = radians(angle); 
	
	// dont need to compute this more than once..
	float c = cos(theta);
	float s = sin(theta);

	// rotation matrix
	rotmat = mat2(c,s,-s,c);

    // perform standard transform on vertex
    gl_Position = ftransform();

    // transform texcoords
    texcoord0 = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);
	
}