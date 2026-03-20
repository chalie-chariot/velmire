shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 shadow_color : source_color = vec4(0.2, 0.15, 0.3, 1.0);
uniform vec4 highlight_color : source_color = vec4(0.8, 0.7, 1.0, 1.0);
uniform float shadow_threshold : hint_range(0.0, 1.0) = 0.4;
uniform float highlight_threshold : hint_range(0.0, 1.0) = 0.85;
uniform float outline_thickness : hint_range(0.0, 0.01) = 0.003;
uniform vec4 outline_color : source_color = vec4(0.04, 0.03, 0.08, 1.0);

void vertex() {
	VERTEX += NORMAL * outline_thickness;
}

void fragment() {
	vec3 light_dir = normalize(vec3(0.4, 0.8, 0.4));
	vec3 normal_world = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float diff = dot(normal_world, light_dir) * 0.5 + 0.5;

	vec4 color;
	if (diff > highlight_threshold) {
		color = highlight_color;
	} else if (diff > shadow_threshold) {
		color = base_color;
	} else {
		color = shadow_color;
	}

	ALBEDO = color.rgb;
}
