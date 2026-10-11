extends CanvasLayer
@onready var finish: Area2D = %finish
@export var sacrifices = 0
@onready var score_label: Label = $Panel/Score_Label

func _ready() -> void:
	score_label.visible_ratio = 1

func add_point():
	if(sacrifices>=0):
		score_label.text = "Sacrifices left: " + str(sacrifices)
	
func _process(_delta: float) -> void:
	add_point()
	if(sacrifices == 0):
		finish.set_collision_mask_value(2,true)
