varying vec2 in_TexelCoord;
uniform sampler2D in_MergedCascade1;
uniform sampler2D in_MergedCascade2;
uniform sampler2D in_MergedCascade3;
uniform sampler2D in_MergedCascade4;

#define SRGB(c) pow(c.rgb, vec3(2.2))
#define LINEAR(c) pow(c.rgb, vec3(1.0 / 2.2))

void main() {
	gl_FragColor =
		(texture2D(in_MergedCascade1, in_TexelCoord - (vec2(1.0, 0.0) / vec2(1920,1080))) * 0.25) +
		(texture2D(in_MergedCascade2, in_TexelCoord - (vec2(0.0, -1.0) / vec2(1920,1080))) * 0.25) +
		(texture2D(in_MergedCascade3, in_TexelCoord - (vec2(-1.0, 0.0) / vec2(1920,1080))) * 0.25) +
		(texture2D(in_MergedCascade4, in_TexelCoord - (vec2(0.0, 1.0) / vec2(1920,1080))) * 0.25);
	gl_FragColor = vec4(LINEAR(gl_FragColor), 1.0);
}