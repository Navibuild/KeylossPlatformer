shader_type canvas_item;
// Pixelated circular wipe used for scene transitions.
// progress 0 = fully open, 1 = fully closed.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 center = vec2(0.5, 0.5);
uniform vec4 color : source_color = vec4(0.07, 0.05, 0.12, 1.0);
uniform float pixel_size = 6.0;

void fragment() {
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	vec2 px = floor(UV * screen / pixel_size) * pixel_size + pixel_size * 0.5;
	vec2 d = px - center * screen;
	float max_r = length(max(center, 1.0 - center) * screen);
	float r = (1.0 - progress) * max_r * 1.05;
	COLOR = vec4(color.rgb, step(r, length(d)) * color.a);
}
