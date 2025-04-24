/*
	Updates to "render_*" variables go here before radiance_* variables updates.
*/
radiance_index += keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left);
radiance_index = clamp(radiance_index, 0, radiance_count - 1);