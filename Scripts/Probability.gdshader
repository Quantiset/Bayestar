shader_type spatial;
render_mode cull_disabled;

uniform sampler2D prob_map;
uniform sampler2D gradient;


void fragment() {
	float st = sin(TIME * 1.5);
	float prob = texture(prob_map, UV).r;
	vec4 color_gradient = texture(gradient, vec2(min(0.01+prob+prob*(st+2.0)*0.2, 0.99), 0.));
	float pulse = 0.5 + 0.2 * (st+1.0);

	ALBEDO = color_gradient.rgb;
    EMISSION = ALBEDO * pulse * 0.4;
	ALPHA = color_gradient.a;
}

void vertex() {
	float s = texture(prob_map, UV).r;
	VERTEX += NORMAL * 0.01 * (sin(TIME) + 1.0) + 0.02 * s * NORMAL;
}
