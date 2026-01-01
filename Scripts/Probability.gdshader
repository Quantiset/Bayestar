shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform sampler2D prob_map;
uniform sampler2D gradient;


float sample_prob_blur(vec2 uv) {
	vec2 prob_texel_size = vec2(1.0/788.0, 1.0/394.0);
	
	float sum = 0.0;
	
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 offset = vec2(float(x), float(y)) * prob_texel_size;
			sum += texture(prob_map, uv + offset).r;
		}
	}
	
	return sum / 9.0;
}

void fragment() {
	float st = 1.0;
	float prob = sample_prob_blur(UV);
	vec4 color_gradient = texture(gradient, vec2(min(0.01+prob+prob*(st+2.0)*0.2, 0.99), 0.));
	float pulse = 0.5 + 0.2 * (st+1.0);
	
	if (prob < 0.02) {
		discard;
	}
	
	ALBEDO = color_gradient.rgb;
    EMISSION = ALBEDO * pulse * 0.4;
}

