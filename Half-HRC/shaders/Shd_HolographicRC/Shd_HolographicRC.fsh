varying vec2 in_TexelCoord;
uniform sampler2D in_RenderScene;
uniform sampler2D in_DistanceField;
uniform sampler2D in_UpperCascade;
uniform vec2 in_RenderExtent;
uniform vec2 in_CascadeExtent;
uniform float in_CascadeIndex;
uniform float in_CascadeCount;
uniform float in_CascadeFrustum;

#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define SRGB(c) pow(c.rgb, vec3(2.2))
#define LINEAR(c) pow(c.rgb, vec3(1.0 / 2.2))

// Circle marching against a distance field texture (non-volumetric).
vec4 raymarch(vec2 origin, vec2 delta, float interval) {
	for(float ii = 0.0, dd = 0.0, rr = 0.0, ee = 0.00001, scale = length(in_RenderExtent); ii < interval; ii++) {
		vec2 ray = (origin + (delta * rr)) * (1.0 / in_RenderExtent);
		rr += scale * (dd = V2F16(texture2D(in_DistanceField, ray).rg));
		if (rr >= interval || floor(ray) != vec2(0.0)) break;
		if (dd <= ee) return vec4(SRGB(texture2D(in_RenderScene, ray).rgb), 0.0);
	}
	return vec4(0.0, 0.0, 0.0, 1.0);
}

struct PROBE {
	float intrv, index;
	vec2 frust, ortho, probe, merge;
};

PROBE getProbe(vec2 texel, float cascade, int f) {
	const vec4 fx = vec4(1.0, 0.0, -1.0, 0.0);
	const vec4 fy = vec4(0.0, -1.0, 0.0, 1.0);
	const vec4 lx = vec4(1.0, -1.0, -1.0, 1.0);
	const vec4 ly = vec4(-1.0, -1.0, 1.0, 1.0);
	
	float interval = pow(2.0, cascade); // cascade interval.
	vec2 frustum = vec2(fx[f], fy[f]); // frustum direction / delta.
	vec2 limit = vec2(lx[f], ly[f]); // The furthest edge of the frustum (to iterate rays perpendicular to the frustum).
	vec2 perpendicular = vec2(-frustum.y, frustum.x); // Said perpendicular direction to the frustum.
	vec2 orthographic = abs(frustum); // The orthographic (horizontal or vertical) direction of the frustum for memory layout.
	vec2 plane = floor(texel * orthographic) + vec2(0.5); // Get the current planar probe position. x,0 or 0,y.
	vec2 horiz = floor(plane / interval) * interval; // Round the planar coordinate to the nearest plane.
	vec2 verti = texel * orthographic.yx; // Get the position of the probe along or parallel to the plane.
	vec2 rayvh = floor(plane - horiz); // Difference between texel plane pos and actual plane position to get ray index.
	float index = rayvh.x + rayvh.y; // The index resides in either X or Y but not both depending on frustum direction.
	vec2 probe = floor(horiz + verti) + 0.5; // Combine vertical/horiztonal planar positions for full probe position.
	
	// Offset the planar probe position to frustum edge and iterate parallel to plane by ray index.
	// We merge with the immediate probe the end of this ray, so ray end and merge position are the same.
	vec2 merge = probe + (limit * (interval - 1.0)) + (perpendicular * (index * 2.0)) + frustum;
	
	// If the current plane and nearest cN+1 plane overlap raymarching exits immediately and merges.
	if (mod(max(horiz.x, horiz.y), interval * 2.0) == 0.0)
		merge = probe;
	
	return PROBE(interval, index, frustum, orthographic, probe, merge);
}

// Sample two cN+1 directions, interpolate and return.
vec4 getSample(PROBE info, vec2 probe, float index) {
	vec2 mergePos = probe + (info.ortho * min((info.intrv*2.0) - 1.0, index + 0.5));
	vec4 mergePos1 = (floor(mergePos/in_CascadeExtent) == 0.0)?
		texture2D(in_UpperCascade, mergePos / in_CascadeExtent) : vec4(0.0);
		
	mergePos = probe + (info.ortho * max(0.0, index - 0.5));
	vec4 mergePos2 = (floor(mergePos/in_CascadeExtent) == 0.0)?
		texture2D(in_UpperCascade, mergePos / in_CascadeExtent) : vec4(0.0);
	
	return mix(mergePos1, mergePos2, 0.5);
}

// Merge with two cN+1 directions at two offsets parallel to plane (to avoid diverging frustums)--specific to 1/2 HRC (current variant).
vec4 merge(PROBE info, vec4 sample) {
	if (sample.a < 1.0 || in_CascadeIndex >= in_CascadeCount - 1.0)
		return sample;
	
	return mix(mix(getSample(info, info.merge - info.frust.yx, (info.index * 2.0)), getSample(info, info.merge + info.frust.yx, (info.index * 2.0) + 1.0), 0.5),
		mix(getSample(info, info.merge + info.frust.yx, (info.index * 2.0)), getSample(info, info.merge - info.frust.yx, (info.index * 2.0) + 1.0), 0.5), 0.5);
}

void main() {
	// Get this texel's ray and probe information to raymarch / merge.
	PROBE infos = getProbe(in_TexelCoord * in_CascadeExtent, in_CascadeIndex, int(in_CascadeFrustum));
	
	// Raymarch between the probe on this plane and the probe we want to merge with on the next plane.
	vec4 sample = raymarch(infos.probe, normalize(infos.merge - infos.probe), length(infos.merge - infos.probe));
	
	// Weight the ray by its angle to normalize contribution.
	sample.rgb *= 1.0 - (0.5 * abs((infos.index - (infos.intrv * 0.5)) / (infos.intrv * 0.5)));
	
	// If no hit, merge with the above cascade.
	gl_FragColor = merge(infos, sample);
}

/*
	Casts rays across planes of probes.
	Rays/probes scale 2x exactly.
	Rays are spaced with 1px between their endpoints.
	
	To merge we take the adjacent two probes (not the direct merge probe position.
	This is because pow2 rays, evenly spaced diverge. To avoid divergence we have
	to sample twice as many probes offset by one pixel to push away and toward the
	frustum center to balance merging.
*/