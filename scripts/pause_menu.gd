extends CanvasLayer
## Pause menu (Esc). Runs while the tree is paused (process_mode = Always).

@onready var resume_button: Button = $Root/Panel/VBox/Resume
@onready var sound_button: Button = $Root/Panel/VBox/Sound
@onready var quit_button: Button = $Root/Panel/VBox/Quit

var paused = false


func _ready() -> void:
	hide()
	# Browsers can't close the tab from a game, so hide Quit on the web build.
	quit_button.visible = not OS.has_feature("web")
	_update_sound_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not Game.is_changing_scene():
		get_viewport().set_input_as_handled()
		Pmenu()


func Pmenu():
	if paused:
		_on_resume_pressed()
	else:
		get_tree().paused = true
		paused = true
		show()
		resume_button.grab_focus()
		Game.sfx("tap", -4.0)


func _on_resume_pressed() -> void:
	get_tree().paused = false
	paused = false
	hide()


func _on_restart_level_pressed() -> void:
	Game.restart_level(false)


func _on_level_select_pressed() -> void:
	Game.goto_level_select()


func _on_main_menu_pressed() -> void:
	Game.goto_title()


func _on_sound_pressed() -> void:
	Game.toggle_mute()
	_update_sound_label()


func _update_sound_label() -> void:
	sound_button.text = "Sound: Off" if Game.muted else "Sound: On"


func _on_quit_pressed() -> void:
	get_tree().quit()
