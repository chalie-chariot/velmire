shader_type canvas_item;

uniform vec4 center_color : source_color = vec4(0.102, 0.0, 0.082, 1.0);  // #1A0015
uniform vec4 outer_color : source_color = vec4(0.051, 0.0, 0.031, 1.0);    // #0D0008

void fragment() {
	vec2 center = vec2(0.5, 0.5);
	float dist = distance(UV, center);
	COLOR = mix(center_color, outer_color, smoothstep(0.0, 0.7, dist));
}
