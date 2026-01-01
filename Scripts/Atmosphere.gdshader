// ADAPTED HEAVILY FROM SEBASTIAN LAGUE'S VIDEO ON ATMOSPHERE SHADERS
// https://www.youtube.com/watch?v=DxfEbulyFcY

shader_type spatial;
render_mode unshaded;

uniform sampler2D screen_color_tex : hint_screen_texture;
uniform sampler2D depth_tex : hint_depth_texture;
uniform float z_near;
uniform float z_far;

uniform vec3 planet_position;
uniform float planet_radius;
uniform float atmosphere_radius;
uniform vec3 sun_position;
uniform vec3 camera_position;
uniform mat3 camera_basis;
uniform sampler2D direction_vector;
uniform vec4 min_max_x_y;
uniform float density_falloff = 0.0;
uniform int sample_points = 10;
uniform vec3 scattering_coeffs;

uniform vec4 ocean_col_a = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 ocean_col_b = vec4(0.0, 0.0, 1.0, 1.0);
uniform float ocean_depth_mult = 5.0;
uniform float ocean_alpha_mult = 4.0;

float density_at_point(vec3 point) {
	float height_above_surface = length(point - planet_position) - planet_radius;
	float scaled_height = height_above_surface / (atmosphere_radius - planet_radius);
	float density = exp(-density_falloff * scaled_height) * (1.0 - scaled_height);
	return clamp(density, 0.0, 1.0);
}

float optical_depth(vec3 ray_origin, vec3 ray_dir, float ray_length) {
	float step_size = ray_length / float(sample_points);
	float optical_depth = 0.0;
	
	vec3 local_point = ray_origin;
	for (int i = 0; i < sample_points; i++) {
		float local_density = density_at_point(local_point);
		optical_depth += local_density * step_size;
		local_point += ray_dir * step_size;
	}
	
	return optical_depth;
}

vec2 ray_sphere(vec3 ray_origin, vec3 ray_dir, float rad) {
	vec3 to_earth = ray_origin - planet_position;
	
	float a = 1.0;
	float b = 2.0 * dot(to_earth, ray_dir);
	float c = dot(to_earth, to_earth) - rad * rad;
	
	float discriminant = b*b - 4.0*a*c;
	
	if (discriminant > 0.0) {
		float s = sqrt(discriminant);
		float near = max(0.0, (-b-s) / (2.0*a));
		float far = (-b+s)/(2.0*a);
		if (far > 0.001) {
			return vec2(near, far - near);
		}
	}
	
	return vec2(99999.0, 0.0);
}

void fragment() {
	
	vec4 og_col = texture(screen_color_tex, SCREEN_UV);
	float d_nonlinear = texture(depth_tex, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d_nonlinear);
	
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	
	float linear_distance = -view.z;
	
	float d_linear = abs(linear_distance);
	
	vec4 clip = vec4(SCREEN_UV * 2.0 - 1.0, 1.0, 1.0);
	vec4 dview = INV_PROJECTION_MATRIX * clip;
	vec3 dir_view = normalize(dview.xyz);
	vec3 dir = normalize(camera_basis * dir_view);
	
	vec2 ws = ray_sphere(camera_position, dir, planet_radius);
	float dist_to_water = ws.r;
	float dist_in_water = ws.g;
	float water_view_depth = min(dist_in_water, d_linear - dist_to_water);
	float optical_depth_water = 1.0 - exp(-water_view_depth * ocean_depth_mult);
	float water_alpha = 1.0 - exp(-water_view_depth * ocean_alpha_mult);
	vec4 water_pre_color = mix(ocean_col_a, ocean_col_b, optical_depth_water);
	vec4 water_color = vec4(d_linear);
	water_color = vec4(0.0);
	
	//water_color = vec4(vec3(step(0.0001, min(dist_in_water, linear_distance - dist_to_water))), 1.0);
	
	vec2 rs = ray_sphere(camera_position, dir, atmosphere_radius);
	float dist_to_atmosphere = rs.r;
	float dist_in_atmosphere = rs.g;
	
	float end_dist = min(dist_to_atmosphere + dist_in_atmosphere, d_linear);
	float ray_dist = end_dist - dist_to_atmosphere;
	
	vec3 query_pos = camera_position + dist_to_atmosphere*dir;
	
	vec3 total_color = vec3(0.0);
	float step_size = ray_dist / float(sample_points);
	query_pos += step_size * dir;
	
	float view_optical_depth = 0.0;
	
	for (int i = 0; i < sample_points; i++) {
		query_pos += dir * step_size;
		vec3 to_sun = normalize(sun_position - query_pos);
		float density = density_at_point(query_pos);
		
		if (density > 0.0001) {
			float sun_time_spent = ray_sphere(query_pos, to_sun, atmosphere_radius).y;
			float sun_optical_depth = optical_depth(query_pos, to_sun, sun_time_spent);
			view_optical_depth = optical_depth(query_pos, -dir, float(i+1) * step_size);
			vec3 transmittance = exp(-(sun_optical_depth+view_optical_depth) * scattering_coeffs);
			
			total_color += max(density * transmittance * step_size * scattering_coeffs, vec3(0.0));
		}
	}
	
	ALBEDO = (og_col.rgb + water_color.rgb) * exp(-view_optical_depth) + total_color;
	//ALBEDO = vec3(d_nonlinear);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
