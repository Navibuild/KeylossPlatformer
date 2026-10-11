extends Area2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

func _ready():
	animation_player.play("idle")
func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Player")):
		animation_player.play("Hit")
		Engine.time_scale = 0.5
		timer.start()
		
func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	var current_scene_file = get_tree().current_scene.scene_file_path
	var next_level_number = current_scene_file.to_int() + 1
	var next_level_path
	if(next_level_number < 11):
		next_level_path = "res://scenes/levels/level_" + str(next_level_number) + ".tscn"
	else:
		next_level_path = "res://scenes/levels/game_over.tscn"
	get_tree().change_scene_to_file(next_level_path)
