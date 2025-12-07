shader_type spatial;
render_mode unshaded;

uniform float segments = 120.0;
uniform float cutoff = 0.0;

uniform float time_scale = 10.0;

void vertex() {
	
}

void fragment() {
	if (sin(UV.y * 2.0 * segments * PI + time_scale * TIME) > cutoff) {
		discard;
	}
	
	ALBEDO = vec3(1.0, 0.0, 0.0);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
