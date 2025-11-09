shader_type canvas_item;
// originally based on https://github.com/WittyCognomen/godot-psx-shaders-demo/blob/master/shaders/psx_dither_post.shader
// Modified for Godot 4.x compatibility

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D dither_tex: hint_default_white, repeat_enable, filter_nearest;
uniform float col_depth = 15.0;
uniform bool dither_banding = true;

void fragment() {
	vec4 base_color = texture(screen_texture, SCREEN_UV);
	vec2 dith_size = vec2(textureSize(dither_tex, 0));
	vec2 buf_size = vec2(1.0) / SCREEN_PIXEL_SIZE; // Get screen size in Godot 4
	vec3 dith = texture(dither_tex, SCREEN_UV * (buf_size / dith_size)).rgb - 0.5;
	COLOR.rgb = round(base_color.rgb * col_depth + dith * (dither_banding ? 1.0 : 0.0)) / col_depth;
}
