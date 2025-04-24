surface_depth_disable(true);
game_set_speed(60, gamespeed_fps);

/*
	Naive implementation renders as a square of the nearest POW2 size of resolution provided.
	No render modifiers besides size... HRC is not very dynamically adjustable.
*/
render_width = 1920;
render_height = 1080;
render_diagonal = point_distance(0, 0, render_width, render_height);

radiance_index = 0;
radiance_width = floor(render_width);
radiance_height = floor(render_height);
radiance_count = ceil(logn(2.0, max(radiance_width, radiance_height)));
radiance_width = power(2, radiance_count);
radiance_height = power(2, radiance_count);

show_debug_message("Render Extent: " + string(render_width) + " : " + string(render_height));
show_debug_message("Radiance Extent: " + string(radiance_width) + " : " + string(radiance_height));
show_debug_message("Radiance Cascades: " + string(radiance_count));

radiance_renderlist = ds_list_create();
radiance_scene = surface_build(render_width, render_height, surface_rgba16float, radiance_renderlist);
radiance_world = surface_build(render_width, render_height, surface_rgba16float, radiance_renderlist);
radiance_jfa = surface_build(render_width, render_height, surface_rgba8unorm, radiance_renderlist);
radiance_sdf = surface_build(render_width, render_height, surface_rgba8unorm, radiance_renderlist);

radiance_frustums = array_create(4, INVALID_SURFACE);
for(var i = 0; i < 4; i++)
	radiance_frustums[i] = surface_build(radiance_width, radiance_height, surface_rgba16float, radiance_renderlist);

radiance_cascades = array_create(radiance_count, INVALID_SURFACE);
for(var i = 0; i < radiance_count; i++) {
	var extent = power(2, radiance_count);
	radiance_cascades[i] = surface_build(extent, extent, surface_rgba16float, radiance_renderlist);
}

radiance_u_shader = Shd_HolographicRC;
radiance_u_RenderScene = texture(radiance_u_shader, "in_RenderScene");
radiance_u_DistanceField = texture(radiance_u_shader, "in_DistanceField");
radiance_u_UpperCascade = texture(radiance_u_shader, "in_UpperCascade");
radiance_u_RenderExtent = uniform(radiance_u_shader, "in_RenderExtent");
radiance_u_CascadeExtent = uniform(radiance_u_shader, "in_CascadeExtent");
radiance_u_CascadeIndex = uniform(radiance_u_shader, "in_CascadeIndex");
radiance_u_CascadeCount = uniform(radiance_u_shader, "in_CascadeCount");
radiance_u_CascadeFrustum = uniform(radiance_u_shader, "in_CascadeFrustum");

frustumsum_u_shader = Shd_HolographicSUM;
frustumsum_u_MergedCascade1 = texture(frustumsum_u_shader, "in_MergedCascade1");
frustumsum_u_MergedCascade2 = texture(frustumsum_u_shader, "in_MergedCascade2");
frustumsum_u_MergedCascade3 = texture(frustumsum_u_shader, "in_MergedCascade3");
frustumsum_u_MergedCascade4 = texture(frustumsum_u_shader, "in_MergedCascade4");

radiance_u_jumpflood = Shd_JumpFlood;
radiance_u_jumpflood_uRenderExtent = uniform(radiance_u_jumpflood, "in_RenderExtent");
radiance_u_jumpflood_uJumpDistance = uniform(radiance_u_jumpflood, "in_JumpDistance");

radiance_u_distancefield = Shd_DistanceField;
radiance_u_distancefield_uRenderExtent = uniform(radiance_u_distancefield, "in_RenderExtent");