extends Control
## Level select: one row of keycap buttons per world. Levels unlock in order;
## cleared levels turn green and show their best time.

const WORLD_COLORS := [Color("7fd0ff"), Color("ffb347"), Color("e08ae0")]
const TEX := {
	"normal": preload("res://assets/ui/lvl_normal.png"),
	"hover": preload("res://assets/ui/lvl_hover.png"),
	"pressed": preload("res://assets/ui/lvl_pressed.png"),
	"done": preload("res://assets/ui/lvl_done.png"),
	"locked": preload("res://assets/ui/lvl_locked.png"),
	"focus": preload("res://assets/ui/btn_focus.png"),
}
const LOCK := preload("res://assets/ui/lock.png")
const CHECK := preload("res://assets/ui/check.png")

@onready var worlds_box: VBoxContainer = $Panel/Worlds
@onready var info: Label = $Info/Label

var _buttons: Array[Button] = []


func _ready() -> void:
	_build()
	$Progress.text = "%d / %d CLEARED" % [Game.completed_count(), Game.LEVEL_COUNT]
	var start := clampi(Game.unlocked, 1, Game.LEVEL_COUNT)
	if Game.completed_count() >= Game.LEVEL_COUNT:
		start = 1
	_buttons[start - 1].grab_focus()
	_show_info(start)


func _build() -> void:
	var rows := ceili(Game.LEVEL_COUNT / float(Game.LEVELS_PER_WORLD))
	for w in rows:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var name_label := Label.new()
		name_label.text = Game.WORLD_NAMES[w].to_upper() if w < Game.WORLD_NAMES.size() else "WORLD %d" % (w + 1)
		name_label.custom_minimum_size = Vector2(150, 0)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", WORLD_COLORS[w % WORLD_COLORS.size()])
		row.add_child(name_label)
		for i in Game.LEVELS_PER_WORLD:
			var n := w * Game.LEVELS_PER_WORLD + i + 1
			if n <= Game.LEVEL_COUNT:
				row.add_child(_make_button(n))
		worlds_box.add_child(row)


func _make_button(n: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(90, 84)
	b.add_theme_font_size_override("font_size", 32)
	var unlocked := Game.is_unlocked(n)
	var done := Game.is_completed(n)
	var normal := "done" if done else "normal"
	b.add_theme_stylebox_override("normal", _style(TEX[normal], false))
	b.add_theme_stylebox_override("hover", _style(TEX["done"] if done else TEX["hover"], false))
	b.add_theme_stylebox_override("pressed", _style(TEX["pressed"], true))
	b.add_theme_stylebox_override("hover_pressed", _style(TEX["pressed"], true))
	b.add_theme_stylebox_override("disabled", _style(TEX["locked"], false))
	b.add_theme_stylebox_override("focus", _style(TEX["focus"], false))
	if unlocked:
		b.text = str(n)
		if done:
			b.add_theme_color_override("font_color", Color("0a5a26"))
			b.add_theme_color_override("font_hover_color", Color("0a5a26"))
			b.add_theme_color_override("font_focus_color", Color("0a5a26"))
			var check := TextureRect.new()
			check.texture = CHECK
			check.position = Vector2(60, 6)
			check.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(check)
	else:
		b.disabled = true
		b.icon = LOCK
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_on_level_pressed.bind(n))
	b.focus_entered.connect(_show_info.bind(n))
	b.mouse_entered.connect(_show_info.bind(n))
	b.focus_entered.connect(Game.sfx.bind("tap", -12.0))
	_buttons.append(b)
	return b


func _style(tex: Texture2D, pressed: bool) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.texture_margin_left = 9
	s.texture_margin_right = 9
	s.texture_margin_top = 18 if pressed else 9
	s.texture_margin_bottom = 9 if pressed else 18
	s.content_margin_top = 12 if pressed else 3
	s.content_margin_bottom = 6 if pressed else 15
	return s


func _show_info(n: int) -> void:
	var text := "LEVEL %d  %s" % [n, Game.level_name(n).to_upper()]
	if not Game.is_unlocked(n):
		text = "LEVEL %d  LOCKED - CLEAR LEVEL %d FIRST" % [n, n - 1]
	elif Game.is_completed(n):
		text += "   BEST %s" % Game.format_time(Game.best_times[n])
	info.text = text


func _on_level_pressed(n: int) -> void:
	if Game.is_unlocked(n):
		Game.play_level(n)


func _on_back_pressed() -> void:
	Game.goto_title()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		Game.goto_title()
	# Developer shortcut: in debug builds (running from the editor) U unlocks every level.
	elif OS.is_debug_build() and event is InputEventKey and event.pressed and event.keycode == KEY_U:
		Game.unlocked = Game.LEVEL_COUNT
		Game.save()
		get_tree().reload_current_scene()
