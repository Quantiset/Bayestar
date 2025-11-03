shader_type spatial;

uniform sampler2D map;
uniform sampler2D cloud_cover;
uniform sampler2D nightmap;
uniform sampler2D prob_map;
uniform sampler2D normalmap;
uniform sampler2D gradient;

uniform float cloud_speed = 0.0005;

uniform vec4 color_b : source_color;

uniform vec3 light_direction;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 col = texture(map, UV);
	float clouds = texture(cloud_cover, UV + vec2(TIME * cloud_speed, 0.)).r;
	vec3 earth_col = mix(col.rgb, vec3(1.), clouds * 1.0);
	
	float prob = texture(prob_map, UV).r;
	vec4 color_gradient = texture(gradient, vec2(min(0.01+prob, 1.), 0.));
	
	vec3 view_light = normalize((VIEW_MATRIX * vec4(light_direction, 0.0)).xyz);
	if (dot(NORMAL, view_light) > 0.0) {
		float ss = min(dot(NORMAL, view_light), 0.1) * 10.0;
		vec4 light_color = texture(nightmap, UV);
		float light_s = length(light_color.rgb) * ss;
		earth_col = mix(earth_col, light_color.rgb, min(3.0 * light_s, 1.0));
		EMISSION = earth_col.rgb * max(light_s-0.1, 0.);
	}
	
	ALBEDO = earth_col;
	NORMAL_MAP = texture(normalmap, UV).rgb;
}
