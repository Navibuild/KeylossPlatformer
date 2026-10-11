extends Control
## Start screen: animated keycap logo over the key art, plus Play / Level Select / Quit.

const TITLE := "KEYLOSS"
const KEY_TEX := preload("res://assets/ui/logo_key.png")
const KEY_TEX_ORANGE := preload("res://assets/ui/logo_key_orange.png")
const KNIGHT := preload("res://assets/sprites/knight.png")
const ARROW := preload("res://assets/sprites/pixil-frame-0.png")
const FLAG := preload("res://assets/sprites/Checkpoint (Flag Out) (64x64).png")
const GROUND_Y := 184.0  # in key-art pixels (the art is drawn at 3x)

@onready var logo: HBoxContainer = $Logo
@onready var actors: Node2D = $Actors
@onready var play_button: Button = $Menu/Play
@onready var quit_button: Button = $Menu/Quit

var _caps: Array[Control] = []
var _blocks: Array[Sprite2D] = []
var _time := 0.0
var _popping := -1


func _ready() -> void:
	_build_logo()
	_build_actors()
	var cleared := Game.completed_count()
	$Progress.text = "%d / %d LEVELS CLEARED" % [cleared, Game.LEVEL_COUNT]
	if cleared >= Game.LEVEL_COUNT:
		play_button.text = "Play Again"
	elif Game.unlocked > 1:
		play_button.text = "Continue  %d" % Game.unlocked
	quit_button.visible = not OS.has_feature("web")
	play_button.grab_focus()
	for b in $Menu.get_children():
		b.focus_entered.connect(Game.sfx.bind("tap", -12.0))
	_schedule_pop()


func _process(delta: float) -> void:
	_time += delta
	for i in _caps.size():
		if i == _popping:
			continue
		# Wave, snapped to 3px (one art pixel) so it stays crunchy.
		_caps[i].position.y = snappedf(sin(_time * 2.4 - i * 0.7) * 4.0, 3.0)
	for i in _blocks.size():
		_blocks[i].position.y = _blocks[i].get_meta("home_y") + roundf(sin(_time * 2.2 + i * 1.3) * 1.5)


func _build_logo() -> void:
	for i in TITLE.length():
		var cell := Control.new()
		cell.custom_minimum_size = Vector2(66, 72)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cap := Control.new()
		cap.size = Vector2(66, 72)
		cap.pivot_offset = Vector2(33, 36)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var tex := TextureRect.new()
		tex.texture = KEY_TEX if i < 3 else KEY_TEX_ORANGE
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap.add_child(tex)
		var letter := Label.new()
		letter.text = TITLE[i]
		letter.size = Vector2(66, 57)
		letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		letter.add_theme_font_size_override("font_size", 48)
		letter.add_theme_constant_override("outline_size", 0)
		letter.add_theme_color_override("font_color", Color("3a2a2a") if i < 3 else Color("5a2400"))
		cap.add_child(letter)
		cell.add_child(cap)
		logo.add_child(cell)
		_caps.append(cap)


func _build_actors() -> void:
	# The knight, idling at the left edge of the cliff.
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_speed("idle", 8)
	for i in 4:
		var a := AtlasTexture.new()
		a.atlas = KNIGHT
		a.region = Rect2(i * 32, 0, 32, 32)
		frames.add_frame("idle", a)
	var knight := AnimatedSprite2D.new()
	knight.sprite_frames = frames
	knight.position = Vector2(84, GROUND_Y - 12)
	knight.play("idle")
	actors.add_child(knight)

	# Three sacrifice blocks hovering over the path: left, jump, right.
	for i in 3:
		var block := Sprite2D.new()
		block.texture = ARROW
		block.rotation = [-PI / 2, 0.0, PI / 2][i]
		block.position = Vector2(124 + i * 26, 156 - (8 if i == 1 else 0))
		block.set_meta("home_y", block.position.y)
		actors.add_child(block)
		_blocks.append(block)

	# The goal flag across the pit.
	var flag := Sprite2D.new()
	flag.texture = FLAG
	flag.hframes = 26
	flag.frame = 7
	flag.scale = Vector2(0.46875, 0.40625)
	flag.position = Vector2(318, GROUND_Y - 13)
	actors.add_child(flag)


## Every few seconds one of the LOSS keys pops off the logo, falls away, then drops back in.
func _schedule_pop() -> void:
	await get_tree().create_timer(randf_range(2.5, 4.0)).timeout
	if not is_inside_tree():
		return
	_popping = randi_range(3, TITLE.length() - 1)
	var cap := _caps[_popping]
	var t := create_tween()
	t.tween_property(cap, "position:y", -30.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(cap, "rotation", deg_to_rad(randf_range(-25, 25)), 0.18)
	t.tween_property(cap, "position:y", 700.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(cap, "rotation", deg_to_rad(randf_range(-160, 160)), 0.7)
	t.tween_interval(0.6)
	t.tween_callback(func():
		cap.position.y = -260.0
		cap.rotation = 0.0)
	t.tween_property(cap, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await t.finished
	_popping = -1
	_schedule_pop()


func _on_play_pressed() -> void:
	if Game.completed_count() >= Game.LEVEL_COUNT:
		Game.play_level(1)
	else:
		Game.play_level(Game.unlocked)


func _on_level_select_pressed() -> void:
	Game.goto_level_select()


func _on_quit_pressed() -> void:
	get_tree().quit()
