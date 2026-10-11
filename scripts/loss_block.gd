class_name LossBlock
extends Area2D
## Base for every "sacrifice" block. While the player is inside, pressing one of
## the block's inputs takes that input away for the rest of the level.
## The press that sacrifices still goes through (the player handles input first),
## so it works as your last use of that input.

const PLAYER_FLAGS := {
	"move_left": "bool_left",
	"move_right": "bool_right",
	"jump": "bool_jump",
}
const COLORS := [Color("ff7e00"), Color("ffa34d"), Color("ffe0b0"), Color("b45500")]

## Inputs this block can take. If there are several, the first one pressed wins.
var actions: Array[String] = []

@onready var goal_list: CanvasLayer = %Goal_list
@onready var player: CharacterBody2D = %Player
@onready var sprite: Sprite2D = $Sprite2D

var p1_is_in_area := false
var _used := false
var _time := 0.0
var _sprite_home: Vector2


func _ready() -> void:
	set_collision_mask_value(2, true)
	_sprite_home = sprite.position
	_time = position.x * 0.07  # desynchronise the bobbing of neighbouring blocks


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		p1_is_in_area = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Player"):
		p1_is_in_area = false


func _process(delta: float) -> void:
	if _used:
		return
	_time += delta
	# Gentle 1px bob, snapped to whole pixels so the art stays crisp.
	sprite.position.y = _sprite_home.y + roundf(sin(_time * 2.6))
	var glow := 0.5 + 0.5 * sin(_time * 9.0) if p1_is_in_area else 0.0
	sprite.modulate = Color(1, 1, 1).lerp(Color(1.6, 1.45, 1.2), glow)
	sprite.scale = Vector2.ONE * (1.0 + 0.1 * glow if p1_is_in_area else 1.0)

	if not p1_is_in_area:
		return
	for action in actions:
		if Input.is_action_just_pressed(action):
			sacrifice(action)
			return


func sacrifice(action: String) -> void:
	_used = true
	var still_had_it: bool = player.get(PLAYER_FLAGS[action])
	player.set(PLAYER_FLAGS[action], false)
	# Giving up an input you'd already lost (possible with the L/R block) is free
	# and doesn't push you anywhere.
	if still_had_it and player.has_method("on_input_sacrificed"):
		player.on_input_sacrificed(action)
	goal_list.sacrifices -= 1
	set_deferred("monitoring", false)
	set_process(false)

	var center := global_position + Vector2(0, -10)
	var parent := get_parent()
	FX.burst(parent, center, COLORS, 26, 95.0, 0.65, 220.0, 1.5)
	FX.burst(parent, center, [Color.WHITE], 8, 40.0, 0.3, 0.0, 1.0)
	FX.popup(parent, center + Vector2(0, -6), "-" + _action_label(action), Color("ffb347"))
	Game.sfx("sacrifice", -8.0)
	Game.shake(2.0, 0.22)
	if goal_list.has_method("on_sacrifice"):
		goal_list.on_sacrifice(action)

	var t := create_tween()
	t.tween_property(sprite, "scale", Vector2.ONE * 1.6, 0.12).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "modulate", Color(3, 3, 3, 0), 0.18)
	t.tween_callback(hide)


static func _action_label(action: String) -> String:
	match action:
		"move_left": return "LEFT"
		"move_right": return "RIGHT"
		"jump": return "JUMP"
	return action.to_upper()
