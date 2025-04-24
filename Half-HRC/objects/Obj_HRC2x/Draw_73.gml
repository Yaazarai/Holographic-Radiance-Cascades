var gpu_blend = gpu_get_blendenable();
var gpu_texrepeat = gpu_get_tex_repeat();
var gpu_filter = gpu_get_tex_filter();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);
gpu_set_tex_filter(true);

	radiance_jfaseed(radiance_world.memory, radiance_jfa.memory, radiance_sdf.memory, Shd_SeedJumpFlood);
	radiance_jumpflood(radiance_sdf.memory, radiance_jfa.memory, Shd_JumpFlood, radiance_u_jumpflood_uRenderExtent, radiance_u_jumpflood_uJumpDistance, render_width, render_height);
	radiance_distancefield(radiance_jfa.memory, radiance_sdf.memory, Shd_DistanceField, radiance_u_distancefield_uRenderExtent, render_width, render_height);
	
	for(var j = 0; j < 4; j++)
	for(var i = radiance_count - 1; i >= 0; i--) {
		shader_set(radiance_u_shader);
		shader_texture(radiance_u_RenderScene, surface_source(radiance_world));
		shader_texture(radiance_u_DistanceField, surface_source(radiance_sdf));
		shader_texture(radiance_u_UpperCascade, surface_source(radiance_cascades[(i+1) % radiance_count]));
		shader_vec2(radiance_u_RenderExtent, render_width, render_height);
		shader_vec2(radiance_u_CascadeExtent, radiance_width, radiance_height);
		shader_float(radiance_u_CascadeIndex, i);
		shader_float(radiance_u_CascadeCount, radiance_count);
		shader_float(radiance_u_CascadeFrustum, j);
			// Render the current cascade...
			surface_set_target(surface_source(radiance_cascades[i]));
			draw_clear_alpha(c_black, 0);
				// Pass in the previous cascade...
				draw_sprite_stretched(Spr_ScreenTexture, 0, 0, 0, radiance_width, radiance_height);
			surface_reset_target();
		shader_reset();
		
		if (i == 0) {
			surface_set_target(surface_source(radiance_frustums[j]));
				draw_clear_alpha(c_black, 1);
				draw_surface(surface_source(radiance_cascades[0]), 0, 0);
			surface_reset_target();
		}
	}
	
	shader_set(frustumsum_u_shader);
	shader_texture(frustumsum_u_MergedCascade1, surface_source(radiance_frustums[0]));
	shader_texture(frustumsum_u_MergedCascade2, surface_source(radiance_frustums[1]));
	shader_texture(frustumsum_u_MergedCascade3, surface_source(radiance_frustums[2]));
	shader_texture(frustumsum_u_MergedCascade4, surface_source(radiance_frustums[3]));
		// Render the current cascade...
		surface_set_target(surface_source(radiance_scene));
			draw_clear_alpha(c_black, 1);
			// Sets default nrender geometry...
			draw_sprite_stretched(Spr_ScreenTexture, 0, 0, 0, radiance_width, radiance_height);
		surface_reset_target();
	shader_reset();

gpu_set_blendenable(gpu_blend);
gpu_set_texrepeat(gpu_texrepeat);
gpu_set_tex_filter(gpu_filter);

var xscale = render_width / radiance_width;
var yscale = render_height / radiance_height;
//draw_surface_ext(surface_source(radiance_world), 0, 0, 1, 1, 0, c_white, 1.0);
//draw_surface_ext(surface_source(radiance_sdf), 0, 0, 1, 1, 0, c_white, 1.0);
draw_surface_ext(surface_source(radiance_scene), 0, 0, 1, 1, 0, c_white, 1.0);

draw_set_font(Font1);
draw_set_color(c_yellow);
draw_text(5,  5, "Frame Time:   " + string(delta_time / 1000) + " / " + string(1000 * (1.0/game_get_speed(gamespeed_fps))));
//draw_text(5, 46, "Show Cascade: " + string(radiance_index));
//draw_text(5, 87, "Show Frustum: " + string(radiance_frustum));
draw_set_color(c_white);