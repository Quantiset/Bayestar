shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform sampler2D cloud_map;

void fragment() {
	vec4 cloud = texture(cloud_map, UV+vec2(TIME*0.000, 0.));

	ALPHA = smoothstep(0.15, 0.9, cloud.r);
}

void vertex() {
	VERTEX += NORMAL * 0.006;
}
