
varying vec2 texcoord0;
varying vec2 texcoord1;
varying vec2 texcoord2;
varying vec2 texcoord3;
varying vec2 texcoord4;
varying vec2 texcoord5;
varying vec2 texcoord6;
varying vec2 texcoord7;
varying vec2 texcoord8;

uniform float blur;

void main()
{
    // perform standard transform on vertex
    gl_Position = ftransform();

    // transform texcoords
    texcoord0 = vec2(gl_TextureMatrix[0] * gl_MultiTexCoord0);

	texcoord1 = texcoord0 + vec2(-blur, -blur);
	texcoord2 = texcoord0 + vec2(+blur, -blur);
	texcoord3 = texcoord0 + vec2(+blur, +blur);
	texcoord4 = texcoord0 + vec2(-blur, +blur);
	texcoord5 = texcoord0 + vec2(0.0, -blur);
	texcoord6 = texcoord0 + vec2(0.0, +blur);
	texcoord7 = texcoord0 + vec2(+blur, 0.0);
	texcoord8 = texcoord0 + vec2(-blur, 0.0);
}