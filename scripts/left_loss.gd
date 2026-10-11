extends Area2D
@onready var goal_list: CanvasLayer = %Goal_list
@onready var player: CharacterBody2D = %Player

var p1_is_in_area = false

func _ready() -> void:
	self.set_collision_mask_value(2,true)

func _on_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Player")):
		p1_is_in_area = true

func _on_body_exited(body: Node2D) -> void:
	if (body.is_in_group("Player")):
		p1_is_in_area = false
		
func _remove():
			self.set_collision_mask_value(8,true)
			goal_list.sacrifices -= 1
			self.hide()
			set_process(false)

func _process(_delta) -> void:
	if(p1_is_in_area):
		if Input.is_action_just_pressed("move_left"):
			player.bool_left = false
			_remove()
