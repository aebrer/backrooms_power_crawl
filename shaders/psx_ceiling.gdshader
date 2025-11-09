shader_type spatial;
render_mode diffuse_lambert, vertex_lighting, cull_disabled, shadows_disabled, depth_prepass_alpha, blend_mix, specular_disabled;

// Global uniforms
global uniform float precision_multiplier : hint_range(0.0, 1.0) = 1.0;

// Base PSX uniforms
uniform vec4 modulate_color : source_color = vec4(1.0);
uniform sampler2D albedoTex : source_color, filter_nearest, repeat_enable;
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform vec2 uv_offset = vec2(0.0, 0.0);
uniform vec2 uv_pan_velocity = vec2(0.0);

// Ceiling fade uniforms
uniform bool enable_ceiling_fade = true;

// Screen-space vignette (camera-based)
uniform float screen_fade_inner_radius : hint_range(0.0, 1.0) = 0.35;
uniform float screen_fade_outer_radius : hint_range(0.0, 1.0) = 0.85;
uniform float screen_fade_power : hint_range(0.1, 4.0) = 2.0;

// World-space vignette (player-based cylinder)
uniform vec3 player_world_position = vec3(0.0);
uniform float player_fade_inner_radius : hint_range(0.0, 20.0) = 3.0;
uniform float player_fade_outer_radius : hint_range(0.0, 20.0) = 8.0;
uniform float player_fade_power : hint_range(0.1, 4.0) = 2.0;

// Wireframe rendering
uniform vec4 wireframe_color : source_color = vec4(0.0, 1.0, 0.8, 0.5);
uniform float wire_width : hint_range(0.0, 40.0) = 8.0;
uniform float wire_smoothness : hint_range(0.0, 0.1) = 0.01;
uniform float wireframe_threshold : hint_range(0.0, 1.0) = 0.6;

// Varying variables for wireframe and world position
varying vec3 barys;
varying vec3 world_position;
varying vec2 screen_uv;

// PSX vertex snapping
const vec2 base_snap_res = vec2(160.0, 120.0);
vec4 get_snapped_pos(vec4 base_pos) {
	vec4 snapped_pos = base_pos;
	snapped_pos.xyz = base_pos.xyz / base_pos.w;
	vec2 snap_res = floor(base_snap_res * precision_multiplier);
	snapped_pos.x = floor(snap_res.x * snapped_pos.x) / snap_res.x;
	snapped_pos.y = floor(snap_res.y * snapped_pos.y) / snap_res.y;
	snapped_pos.xyz *= base_pos.w;
	return snapped_pos;
}

float calculate_screen_space_fade() {
	// Use screen UV passed from vertex shader
	vec2 screen_center = vec2(0.5, 0.5);
	vec2 uv_from_center = screen_uv - screen_center;
	float dist_from_center = length(uv_from_center);
	dist_from_center = dist_from_center / 0.707;
	float fade_factor = smoothstep(screen_fade_inner_radius, screen_fade_outer_radius, dist_from_center);
	fade_factor = pow(fade_factor, screen_fade_power);
	return fade_factor;
}

float calculate_world_space_fade() {
	vec2 player_pos_xz = player_world_position.xz;
	vec2 world_pos_xz = world_position.xz;
	float dist_from_player = length(world_pos_xz - player_pos_xz);
	float fade_factor = smoothstep(player_fade_inner_radius, player_fade_outer_radius, dist_from_player);
	fade_factor = pow(fade_factor, player_fade_power);
	return fade_factor;
}

float calculate_combined_fade() {
	float screen_fade = calculate_screen_space_fade();
	float world_fade = calculate_world_space_fade();
	return min(screen_fade, world_fade);
}

void vertex() {
	// UV panning
	UV = UV * uv_scale + uv_offset;
	UV += uv_pan_velocity * TIME;

	// Barycentric coordinates for wireframe
	int index = VERTEX_ID % 3;
	if (index == 0) {
		barys = vec3(1.0, 0.0, 0.0);
	} else if (index == 1) {
		barys = vec3(0.0, 1.0, 0.0);
	} else {
		barys = vec3(0.0, 0.0, 1.0);
	}

	// World position for distance fade
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// PSX vertex snapping
	POSITION = get_snapped_pos(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	POSITION /= abs(POSITION.w);

	// Calculate screen UV for screen-space vignette
	// Convert clip space to NDC (-1 to 1), then to UV (0 to 1)
	vec4 clip_pos = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 ndc = clip_pos.xyz / clip_pos.w;
	screen_uv = ndc.xy * 0.5 + 0.5;

	VERTEX = VERTEX;
}

void fragment() {
	// Base PSX rendering
	vec4 color_base = COLOR * modulate_color;
	vec4 texture_color = texture(albedoTex, UV);
	ALBEDO = (color_base * texture_color).rgb;
	ALPHA = texture_color.a * color_base.a;

	// Ceiling fade system
	if (enable_ceiling_fade) {
		float fade = calculate_combined_fade();

		// fade = 0.0 at center/near player, 1.0 at edges/far from player
		// Low fade = wireframe, high fade = opaque

		if (fade < wireframe_threshold) {
			// Wireframe rendering
			vec3 deltas = fwidth(barys);
			vec3 barys_s = smoothstep(
				deltas * wire_width - wire_smoothness,
				deltas * wire_width + wire_smoothness,
				barys
			);
			float wire_mix = min(barys_s.x, min(barys_s.y, barys_s.z));

			ALBEDO = mix(wireframe_color.rgb, ALBEDO, wire_mix);
			ALPHA = mix(wireframe_color.a, 0.0, wire_mix);

			if (ALPHA < 0.01) {
				discard;
			}
		} else {
			// Fade in based on distance
			ALPHA *= fade;
			if (ALPHA < 0.01) {
				discard;
			}
		}
	}
}
