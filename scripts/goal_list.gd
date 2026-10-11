extends CanvasLayer
## In-level HUD: level name, which inputs you still have and how many sacrifices
## are left. Opens the goal once every sacrifice has been made.

const KEY_TEXTURES := {
	"bool_left": [preload("res://assets/ui/key_left.png"), preload("res://assets/ui/key_left_lost.png")],
	"bool_jump": [preload("res://assets/ui/key_up.png"), preload("res://assets/ui/key_up_lost.png")],
	"bool_right": [preload("res://assets/ui/key_right.png"), preload("res://assets/ui/key_right_lost.png")],
}
const ACTION_FLAGS := {"move_left": "bool_left", "move_right": "bool_right", "jump": "bool_jump"}

@onready var finish: Area2D = %finish
@onready var player: CharacterBody2D = %Player
@export var sacrifices = 0

@onready var title: Label = $Root/Panel/VBox/Title
@onready var score_label: Label = $Root/Panel/VBox/Row/Info/Score_Label
@onready var caption: Label = $Root/Panel/VBox/Row/Info/Caption
@onready var key_icons := {
	"bool_left": $Root/Panel/VBox/Row/KeyLeft,
	"bool_jump": $Root/Panel/VBox/Row/KeyUp,
	"bool_right": $Root/Panel/VBox/Row/KeyRight,
}
@onready var title_card: Control = $Root/TitleCard
@onready var complete_panel: PanelContainer = $Root/Complete

var _goal_open := false
var _level := 0


func _ready() -> void:
	add_to_group("hud")
	_level = Game.level_from_path(owner.scene_file_path) if owner else 0
	var level_name := Game.level_name(_level).to_upper()
	title.text = "LEVEL %d  %s" % [_level, level_name]
	$Root/TitleCard/Number.text = "LEVEL %d" % _level
	$Root/TitleCard/Name.text = level_name
	for icon in key_icons.values():
		icon.pivot_offset = icon.texture.get_size() / 2.0
	_refresh()
	_play_title_card()
	if sacrifices <= 0:
		# Nothing to sacrifice in this level: the goal starts open, no fanfare.
		_goal_open = true
		finish.call_deferred("activate", false)


func _process(_delta: float) -> void:
	_refresh()
	if sacrifices <= 0 and not _goal_open:
		_goal_open = true
		finish.activate()


## Kept for compatibility with older scenes.
func add_point() -> void:
	_refresh()


func _refresh() -> void:
	if sacrifices > 0:
		caption.text = "SACRIFICES"
		score_label.text = "%d LEFT" % sacrifices
		score_label.modulate = Color.WHITE
	else:
		caption.text = "GOAL"
		score_label.text = "OPEN!"
		score_label.add_theme_color_override("font_color", Color("8dff9e"))
		score_label.modulate.a = 0.75 + 0.25 * sin(Time.get_ticks_msec() / 120.0)
	for flag in key_icons:
		var has_input: bool = player.get(flag)
		key_icons[flag].texture = KEY_TEXTURES[flag][0 if has_input else 1]


## Called by a LossBlock right after it takes an input.
func on_sacrifice(action: String) -> void:
	var icon: TextureRect = key_icons.get(ACTION_FLAGS.get(action, ""))
	if icon == null:
		return
	icon.scale = Vector2(1.35, 1.35)
	icon.modulate = Color(2.5, 1.4, 0.6)
	var t := icon.create_tween().set_parallel()
	t.tween_property(icon, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(icon, "modulate", Color.WHITE, 0.4)
	var r := icon.create_tween()
	for i in 4:
		r.tween_property(icon, "rotation", deg_to_rad(10.0 if i % 2 == 0 else -10.0), 0.04)
	r.tween_property(icon, "rotation", 0.0, 0.04)


func show_complete(level: int, time: float) -> void:
	var best: float = Game.best_times.get(level, time)
	var text := "TIME %s" % Game.format_time(time)
	if best < time:
		text += "   BEST %s" % Game.format_time(best)
	else:
		text += "   NEW BEST!"
	$Root/Complete/VBox/Time.text = text
	complete_panel.visible = true
	complete_panel.scale = Vector2(0.6, 0.6)
	complete_panel.modulate.a = 0.0
	var t := complete_panel.create_tween().set_ignore_time_scale(true).set_parallel()
	t.tween_property(complete_panel, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(complete_panel, "modulate:a", 1.0, 0.2)
	title_card.visible = false


func _play_title_card() -> void:
	title_card.modulate.a = 0.0
	var t := title_card.create_tween()
	t.tween_interval(0.25)
	t.tween_property(title_card, "modulate:a", 1.0, 0.35)
	t.tween_interval(1.4)
	t.tween_property(title_card, "modulate:a", 0.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") and not Game.is_changing_scene():
		get_viewport().set_input_as_handled()
		Game.restart_level()
