extends Area2D
## Kills the player on touch, then restarts the level.

@onready var times: Timer = $Timer


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	var shape := body.get_node_or_null("CollisionShape2D")
	if shape == null or shape.is_queued_for_deletion():
		return  # already dying
	Engine.time_scale = 0.5
	shape.queue_free()
	if body.has_method("die"):
		body.die()
	Game.record_death()
	times.start()


func _on_timer_timeout() -> void:
	Game.restart_level()
