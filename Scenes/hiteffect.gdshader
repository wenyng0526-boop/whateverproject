shader_type canvas_item;

uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);

	vec3 flash_color = mix(
		original_color.rgb,  //original color of card
		vec3(1.0), //RGB
		flash_amount
	);

	COLOR = vec4(flash_color, original_color.a);
}