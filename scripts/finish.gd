extends Area2D
## The level goal. It stays dimmed and untouchable until every sacrifice has been
## made (Goal_list calls activate()), then touching it completes the level.

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer
@onready var sprite: Sprite2D = $Sprite2D

const INACTIVE_TINT := Color(0.55, 0.55, 0.7, 0.55)

var active := false
var _won := false
var _sparkle: CPUParticles2D


func _ready() -> void:
	animation_player.play("idle")
	sprite.modulate = INACTIVE_TINT


## Opens the goal. Pass celebrate = false when a level starts with it already open.
func activate(celebrate := true) -> void:
	if active:
		return
	active = true
	set_collision_mask_value(2, true)
	_start_sparkle()
	if not celebrate:
		sprite.modulate = Color.WHITE
		return
	var t := create_tween()
	t.tween_property(sprite, "modulate", Color(2.2, 2.2, 1.6), 0.15)
	t.tween_property(sprite, "modulate", Color.WHITE, 0.4)
	var center := global_position + Vector2(2, -12)
	FX.burst(get_parent(), center, [Color("fff3a0"), Color("7dffb0"), Color.WHITE], 24, 70.0, 0.7, 60.0)
	FX.popup(get_parent(), center + Vector2(0, -12), "GOAL OPEN!", Color("8dff9e"), 14.0)
	Game.sfx("goal_open", -4.0, 0.0)


func _on_body_entered(body: Node2D) -> void:
	if _won or not body.is_in_group("Player"):
		return
	_won = true
	animation_player.play("Hit")
	Engine.time_scale = 0.5
	timer.start()
	var level := Game.current_level()
	var time := Game.complete_level(level)
	var center := global_position + Vector2(0, -14)
	FX.burst(get_parent(), center, [Color("ff5e7e"), Color("ffd84d"), Color("5ee0ff"), Color("8dff9e")],
		40, 120.0, 1.2, 160.0, 1.0, 70.0)
	Game.sfx("finish", -2.0, 0.0)
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_complete"):
		hud.show_complete(level, time)


func _on_timer_timeout() -> void:
	Engine.time_scale = 1
	Game.next_level(Game.current_level())


func _start_sparkle() -> void:
	_sparkle = CPUParticles2D.new()
	_sparkle.amount = 6
	_sparkle.lifetime = 1.2
	_sparkle.position = Vector2(2, -12)
	_sparkle.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sparkle.emission_rect_extents = Vector2(6, 9)
	_sparkle.direction = Vector2.UP
	_sparkle.spread = 20
	_sparkle.gravity = Vector2(0, -12)
	_sparkle.initial_velocity_min = 2
	_sparkle.initial_velocity_max = 6
	_sparkle.color = Color("fff3a0")
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.3, Color.WHITE)
	_sparkle.color_ramp = ramp
	add_child(_sparkle)
