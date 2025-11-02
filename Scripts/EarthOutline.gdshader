shader_type spatial;

uniform sampler2D map;
uniform sampler2D cloud_cover;
uniform sampler2D prob_map;
uniform sampler2D gradient;

uniform float cloud_speed = 0.0005;

uniform vec4 color_b : source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 col = texture(map, UV);
	float clouds = texture(cloud_cover, UV + vec2(TIME * cloud_speed, 0.)).r;
	vec3 earth_col = mix(col.rgb, vec3(1.), clouds * 1.0);
	
	float prob = texture(prob_map, UV).r;
	vec4 color_gradient = texture(gradient, vec2(min(0.01+prob, 1.), 0.));
	
	ALBEDO = mix(earth_col, color_gradient.rgb, 0.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
