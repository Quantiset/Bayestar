shader_type spatial;

uniform sampler2D map;
uniform sampler2D cloud_cover;
uniform sampler2D nightmap;
uniform sampler2D prob_map;
uniform sampler2D normalmap;
uniform sampler2D height_map;
uniform sampler2D gradient;

uniform float cloud_speed = 0.000;
uniform float depression_strength = 1.0;

uniform vec3 light_direction;

void vertex() {
	vec4 col = texture(height_map, UV);
	float h = length(col.rgb);
	VERTEX *= (h*0.025 + 0.985) - depression_strength*(1.0-step(0.086099, h))*0.003;
}

void fragment() {
	vec4 col = texture(map, UV);

	vec2 moving_uv = UV + vec2(TIME * cloud_speed, 0.0);
	vec4 cloud = texture(cloud_cover, moving_uv);

	vec3 L = normalize(light_direction);
	vec3 N = normalize(NORMAL);

	float u_offset = -L.x * 0.01; 
	float v_offset = -L.y * 0.01;
	
	vec4 shadow_cloud = texture(cloud_cover, moving_uv + vec2(u_offset, v_offset));
	
	vec3 earth_col = mix(col.rgb, col.rgb * 0.6, shadow_cloud.r); 
	
	vec3 view_light = normalize((VIEW_MATRIX * vec4(light_direction, 0.0)).xyz);
	if (dot(NORMAL, view_light) > 0.0) {
		float ss = min(dot(NORMAL, view_light), 0.1) * 10.0;
		vec4 light_color = texture(nightmap, UV);
		float light_s = length(light_color.rgb) * ss;
		earth_col = mix(earth_col, light_color.rgb, min(3.0 * light_s, 1.0));
		EMISSION = earth_col.rgb * max(light_s - 0.1, 0.);
	}

	ALBEDO = earth_col.rgb;
	//NORMAL_MAP = texture(normalmap, UV).rgb;
}
