extends Node2D
## Animated backdrop shared by the title screen and level select:
## the key art plus drifting clouds and floating fireflies. Drawn at 3x scale.

@export var cloud_speed := 4.0

@onready var clouds: Sprite2D = $Clouds


func _process(delta: float) -> void:
	clouds.region_rect.position.x += cloud_speed * delta
