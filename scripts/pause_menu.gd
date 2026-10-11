extends Control
@onready var pause_menu: Control = %"Pause Menu"

var paused = false

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		Pmenu()
		
func Pmenu():
	if paused:
		get_tree().paused = false
		pause_menu.hide()
		
	else:
		get_tree().paused = true
		pause_menu.show()
	paused = !paused


func _on_resume_pressed() -> void:
	get_tree().paused = false
	pause_menu.hide()
	paused = !paused


func _on_main_menu_pressed() -> void:
	_on_resume_pressed()
	get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_restart_level_pressed() -> void:
	_on_resume_pressed()
	get_tree().reload_current_scene()
