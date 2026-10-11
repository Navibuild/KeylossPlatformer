class_name FX
## Small helpers for one-shot visual effects (particle bursts, floating text).

const FONT := preload("res://assets/fonts/PixelOperator8.ttf")
const FONT_BOLD := preload("res://assets/fonts/PixelOperator8-Bold.ttf")


## Spawns a one-shot square-particle burst that frees itself when done.
static func burst(parent: Node, pos: Vector2, colors: Array, amount := 12, speed := 60.0,
		lifetime := 0.5, gravity := 180.0, size := 1.0, spread := 180.0,
		direction := Vector2.UP) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = amount
	p.lifetime = lifetime
	p.direction = direction
	p.spread = spread
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, gravity)
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.scale_amount_min = size
	p.scale_amount_max = size * 2.0
	var ramp := Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.7, Color.WHITE)
	p.color_ramp = ramp
	if colors.size() > 1:
		var g := Gradient.new()
		g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
		g.offsets = PackedFloat32Array()
		g.colors = PackedColorArray()
		for i in colors.size():
			g.add_point(float(i) / colors.size(), colors[i])
		p.color_initial_ramp = g
	elif colors.size() == 1:
		p.color = colors[0]
	p.position = pos
	p.z_index = 50
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.emitting = true
	return p


## Little puff of dust at someone's feet.
static func dust(parent: Node, pos: Vector2, amount := 6) -> void:
	burst(parent, pos, [Color(0.93, 0.89, 0.8, 0.9), Color(0.8, 0.74, 0.62, 0.9)], amount, 28.0,
		0.35, -20.0, 1.0, 70.0, Vector2.UP)


## Text that floats upward and fades out (world space).
static func popup(parent: Node, pos: Vector2, text: String, color := Color.WHITE, rise := 18.0) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_BOLD)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.08, 0.06, 0.12))
	label.add_theme_constant_override("outline_size", 3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 60
	label.size = Vector2(120, 10)
	label.position = pos - Vector2(60, 10)
	parent.add_child(label)
	# Keep it inside the camera view so it isn't cut off at the screen edge.
	var cam := parent.get_viewport().get_camera_2d()
	if cam:
		var half := parent.get_viewport().get_visible_rect().size / cam.zoom / 2.0
		var center := cam.get_screen_center_position()
		var text_w := label.get_minimum_size().x
		label.position.x = clampf(label.position.x, center.x - half.x + 2 - (60 - text_w / 2),
			center.x + half.x - 2 - (60 + text_w / 2))
	var t := label.create_tween().set_ignore_time_scale(true)
	t.tween_property(label, "position:y", label.position.y - rise, 0.9) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.6)
	t.tween_callback(label.queue_free)
