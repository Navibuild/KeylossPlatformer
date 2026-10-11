extends Control
## Ending screen shown after level 15: stats, a celebrating knight and confetti.

const KNIGHT := preload("res://assets/sprites/knight.png")
const FLAG := preload("res://assets/sprites/Checkpoint (Flag Out) (64x64).png")

@onready var actors: Node2D = $Actors


func _ready() -> void:
	var total := 0.0
	for t in Game.best_times.values():
		total += t
	$Panel/VBox/Stats.text = "LEVELS CLEARED  %d / %d\nBEST TIMES TOTAL  %s\nFALLS  %d" % [
		Game.completed_count(), Game.LEVEL_COUNT, Game.format_time(total), Game.total_deaths]
	$Panel/VBox/Buttons/LevelSelect.grab_focus()
	_build_actors()
	_confetti()


func _build_actors() -> void:
	var frames := SpriteFrames.new()
	frames.add_animation("run")
	frames.set_animation_speed("run", 10)
	for i in 8:
		var a := AtlasTexture.new()
		a.atlas = KNIGHT
		a.region = Rect2(i * 32, 64, 32, 32)
		frames.add_frame("run", a)
	var knight := AnimatedSprite2D.new()
	knight.sprite_frames = frames
	knight.position = Vector2(150, 172)
	knight.play("run")
	actors.add_child(knight)
	# Little victory hops back and forth.
	var t := knight.create_tween().set_loops()
	t.tween_property(knight, "position:y", 160.0, 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	t.tween_property(knight, "position:y", 172.0, 0.18).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_interval(0.5)

	var flag := Sprite2D.new()
	flag.texture = FLAG
	flag.hframes = 26
	flag.frame = 25
	flag.scale = Vector2(0.46875, 0.40625)
	flag.position = Vector2(184, 171)
	actors.add_child(flag)


func _confetti() -> void:
	var p := CPUParticles2D.new()
	p.amount = 140
	p.lifetime = 4.0
	p.preprocess = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(200, 4)
	p.position = Vector2(192, -10)
	p.direction = Vector2.DOWN
	p.spread = 30
	p.gravity = Vector2(0, 30)
	p.initial_velocity_min = 10
	p.initial_velocity_max = 30
	p.angular_velocity_min = -200
	p.angular_velocity_max = 200
	p.scale_amount_min = 1.5
	p.scale_amount_max = 2.5
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75])
	g.colors = PackedColorArray([Color("ff5e7e"), Color("ffd84d"), Color("5ee0ff"), Color("8dff9e")])
	p.color_initial_ramp = g
	actors.add_child(p)


func _on_level_select_pressed() -> void:
	Game.goto_level_select()


func _on_title_pressed() -> void:
	Game.goto_title()
