surface_set_target(radiance_world.memory);
draw_clear_alpha(c_black, 0);
	draw_sprite(Spr_SampleScene, 0, 0, 0);
	//draw_set_color($F0FF0F);
	//if (keyboard_check(vk_space))
		//draw_circle(mouse_x, mouse_y, 8, false);
		//var xx = (keyboard_check(vk_space))? (room_width / 2) - 1 : floor(mouse_x / 64) * 64;
		//xx -= 1;
		//var yy = (room_height / 2) - 1;
		
		var xx = floor(mouse_x / 32) * 32;
		var yy = floor(mouse_y / 32) * 32;
		draw_rectangle(xx,yy-192,xx+32,yy+192,false);
	draw_set_color(c_black);
	/*
	var xx = room_width * 0.75;
	var yy = room_height * 0.5;
	for(var j = 0; j < 8; j++)
	for(var i = 0; i < 8 * j; i++) {
		draw_set_color($000000);
		
		var th = radtodeg(((i/(8 * j)) * pi * 2.0 ) + (j * 8)) + ((current_time * 4.0)/(400 - (j * 400)));
		var dx = lengthdir_x(room_width * (0.025 * j), th);
		var dy = lengthdir_y(room_width * (0.025 * j), th);
		if (i % 2 == 0)
			draw_circle(xx + dx, yy + dy, 4+j, false);
		else
			draw_circle(xx + dx, yy + dy, 2+j, false);
	}
	*/
surface_reset_target();