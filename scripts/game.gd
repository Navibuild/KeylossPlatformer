extends Node
## Global game state (autoloaded as "Game").
## Owns the level list, saved progress, scene transitions, screen shake and sound effects.

const LEVEL_COUNT := 15
const LEVELS_PER_WORLD := 5
const SAVE_PATH := "user://keyloss_save.cfg"

const TITLE_SCENE := "res://scenes/ui/title_screen.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const ENDING_SCENE := "res://scenes/levels/game_over.tscn"

const WORLD_NAMES := ["Meadow", "Sunset", "Dusk"]
const LEVEL_NAMES := [
	"First Sacrifice",
	"Momentum",
	"Rest at the Goal",
	"All You Have",
	"Grounded",
	"Focus",
	"Options",
	"No Harm, No Foul",
	"One Way",
	"Let Life Take You",
	"Mid-Flight",
	"Going Up",
	"Leap of Faith",
	"Choose Wisely",
	"Everything",
]

const SOUNDS := {
	"jump": preload("res://assets/sounds/jump.wav"),
	"hurt": preload("res://assets/sounds/hurt.wav"),
	"sacrifice": preload("res://assets/sounds/explosion.wav"),
	"goal_open": preload("res://assets/sounds/power_up.wav"),
	"finish": preload("res://assets/sounds/coin.wav"),
	"tap": preload("res://assets/sounds/tap.wav"),
}

## Highest level the player may start (levels unlock in order).
var unlocked := 1
## level number -> best completion time in seconds.
var best_times: Dictionary = {}
var total_deaths := 0
var muted := false

var _level_time := 0.0
var _timing := false
var _changing := false
var _iris: ColorRect
var _sfx_players: Array[AudioStreamPlayer] = []
var _shake_time := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0
var _shaken_camera: Camera2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()
	_build_iris()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_players.append(p)
	_apply_mute()


# --- Levels -----------------------------------------------------------------

func level_path(n: int) -> String:
	return "res://scenes/levels/level_%d.tscn" % n


## Returns the level number encoded in a scene path ("level_7.tscn" -> 7), or 0.
func level_from_path(path: String) -> int:
	var file := path.get_file()
	if not file.begins_with("level_"):
		return 0
	return file.trim_prefix("level_").trim_suffix(".tscn").to_int()


func current_level() -> int:
	var scene := get_tree().current_scene
	return level_from_path(scene.scene_file_path) if scene else 0


func world_of(n: int) -> int:
	return clampi(floori((n - 1) / float(LEVELS_PER_WORLD)) + 1, 1, WORLD_NAMES.size())


func level_name(n: int) -> String:
	return LEVEL_NAMES[n - 1] if n >= 1 and n <= LEVEL_NAMES.size() else ""


func is_unlocked(n: int) -> bool:
	return n <= unlocked


func is_completed(n: int) -> bool:
	return best_times.has(n)


func completed_count() -> int:
	return best_times.size()


## Called by every level when it loads.
func level_started() -> void:
	_level_time = 0.0
	_timing = true


## Records a win and unlocks the next level. Returns the time taken.
func complete_level(n: int) -> float:
	_timing = false
	var t := _level_time
	if not best_times.has(n) or t < best_times[n]:
		best_times[n] = t
	unlocked = maxi(unlocked, mini(n + 1, LEVEL_COUNT))
	save()
	return t


func record_death() -> void:
	total_deaths += 1
	save()


func play_level(n: int) -> void:
	change_scene(level_path(n))


func next_level(after: int) -> void:
	if after >= LEVEL_COUNT:
		change_scene(ENDING_SCENE)
	else:
		play_level(after + 1)


func restart_level(fast := true) -> void:
	var scene := get_tree().current_scene
	if scene:
		change_scene(scene.scene_file_path, 0.18 if fast else 0.35)


func goto_title() -> void:
	change_scene(TITLE_SCENE)


func goto_level_select() -> void:
	change_scene(LEVEL_SELECT_SCENE)


func format_time(seconds: float) -> String:
	var m := floori(seconds / 60.0)
	var s := fmod(seconds, 60.0)
	return "%d:%05.2f" % [m, s]


# --- Transitions ------------------------------------------------------------

## Closes a pixelated iris around the player (or screen centre), swaps scenes, then reopens.
func change_scene(path: String, duration := 0.35) -> void:
	if _changing:
		return
	_changing = true
	_iris.material.set_shader_parameter("center", _focus_point())
	await _tween_iris(0.0, 1.0, duration)
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	await get_tree().process_frame
	_iris.material.set_shader_parameter("center", _focus_point())
	_changing = false
	await _tween_iris(1.0, 0.0, duration)


func is_changing_scene() -> bool:
	return _changing


func _focus_point() -> Vector2:
	var vp := get_viewport()
	var size := vp.get_visible_rect().size
	var player := get_tree().get_first_node_in_group("Player") as Node2D
	if player and player.is_inside_tree():
		var p := player.get_global_transform_with_canvas().origin + Vector2(0, -24)
		return Vector2(clampf(p.x / size.x, 0.0, 1.0), clampf(p.y / size.y, 0.0, 1.0))
	return Vector2(0.5, 0.5)


func _tween_iris(from: float, to: float, duration: float) -> void:
	_iris.visible = true
	_iris.material.set_shader_parameter("progress", from)
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_method(func(v): _iris.material.set_shader_parameter("progress", v), from, to, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await t.finished
	_iris.visible = to > 0.0


func _build_iris() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_iris = ColorRect.new()
	_iris.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/iris.gdshader")
	_iris.material = mat
	_iris.visible = false
	layer.add_child(_iris)


# --- Juice ------------------------------------------------------------------

func shake(strength := 2.0, duration := 0.25) -> void:
	_shaken_camera = get_viewport().get_camera_2d()
	if _shaken_camera == null:
		return
	_shake_strength = maxf(strength, _shake_strength if _shake_time > 0.0 else 0.0)
	_shake_duration = duration
	_shake_time = duration


func _process(delta: float) -> void:
	# Level timer: in-game time only (stops while paused).
	if _timing and not get_tree().paused:
		_level_time += delta
	if _shake_time <= 0.0:
		return
	_shake_time -= delta
	if not is_instance_valid(_shaken_camera):
		_shake_time = 0.0
		return
	if _shake_time <= 0.0:
		_shaken_camera.offset = Vector2.ZERO
		return
	var k := _shake_time / _shake_duration
	_shaken_camera.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake_strength * k


func sfx(sound: String, volume_db := 0.0, pitch_jitter := 0.08) -> void:
	if not SOUNDS.has(sound):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = SOUNDS[sound]
			p.volume_db = volume_db
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return


func toggle_mute() -> void:
	muted = not muted
	_apply_mute()
	save()


func _apply_mute() -> void:
	AudioServer.set_bus_mute(0, muted)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("mute"):
		toggle_mute()


# --- Save data --------------------------------------------------------------

func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "best_times", best_times)
	cfg.set_value("progress", "deaths", total_deaths)
	cfg.set_value("settings", "muted", muted)
	cfg.save(SAVE_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	unlocked = clampi(cfg.get_value("progress", "unlocked", 1), 1, LEVEL_COUNT)
	best_times = cfg.get_value("progress", "best_times", {})
	total_deaths = cfg.get_value("progress", "deaths", 0)
	muted = cfg.get_value("settings", "muted", false)


func reset_progress() -> void:
	unlocked = 1
	best_times.clear()
	total_deaths = 0
	save()
