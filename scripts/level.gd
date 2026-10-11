extends Node2D
## Root script shared by every level. Adds the world's scenery behind the tiles
## (sun/moon, drifting clouds, two layers of hills), ambient particles and a soft
## vignette, and tells Game the level has started.
##
## World 1 (levels 1-5) is daytime, world 2 (6-10) sunset, world 3 (11-15) dusk.

const SCENERY_Z := -4050  # between the Background (-4096) and Mid (-4000) tile layers
const HORIZON_Y := 96.0   # bottom edge of the hills, hidden behind the ground

const AMBIENT := {
	1: {"color": Color(1, 1, 0.85, 0.7), "gravity": Vector2(4, -3), "amount": 14},   # pollen
	2: {"color": Color(1, 0.62, 0.25, 0.9), "gravity": Vector2(10, 14), "amount": 12}, # leaves
	3: {"color": Color(0.85, 1, 0.55, 0.95), "gravity": Vector2(0, -2), "amount": 16}, # fireflies
}

var world := 1
var _clouds: Sprite2D
var _cloud_speed := 5.0


func _ready() -> void:
	Game.level_started()
	world = Game.world_of(Game.level_from_path(scene_file_path))
	var bounds := _level_bounds()
	_add_scenery(bounds)
	_add_ambient(bounds)
	_add_vignette()


func _process(delta: float) -> void:
	if _clouds:
		_clouds.region_rect.position.x += _cloud_speed * delta


## Horizontal span the camera can show, read from the player's camera limits.
func _level_bounds() -> Rect2:
	var cam := get_node_or_null("Player/Camera2D") as Camera2D
	var left := -128.0
	var right := 272.0
	if cam and cam.limit_left > -100000 and cam.limit_right < 100000:
		left = cam.limit_left
		right = cam.limit_right
	return Rect2(left - 64.0, -200.0, right - left + 128.0, 300.0)


func _add_scenery(bounds: Rect2) -> void:
	var root := Node2D.new()
	root.name = "Scenery"
	root.z_index = SCENERY_Z
	add_child(root)
	move_child(root, 0)
	var w := float(world)
	var dir := "res://assets/backgrounds/"

	if world == 3:
		_strip(root, load(dir + "stars.png"), bounds, -150.0, 0.0)
	var body := Sprite2D.new()
	body.texture = load(dir + "sky_body_%d.png" % world)
	body.centered = true
	body.position = Vector2(bounds.end.x - 150.0, [0.0, -70.0, 40.0, -80.0][world])
	root.add_child(body)

	_clouds = _strip(root, load(dir + "clouds_%d.png" % world), bounds, -94.0, 0.0)
	_cloud_speed = 4.0 + w
	_strip(root, load(dir + "hills_far_%d.png" % world), bounds, HORIZON_Y - 96.0, 0.0)
	_strip(root, load(dir + "hills_near_%d.png" % world), bounds, HORIZON_Y - 72.0, 37.0)


## A horizontally repeating sprite covering the whole level width.
func _strip(parent: Node, tex: Texture2D, bounds: Rect2, top: float, offset_x: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	s.region_enabled = true
	s.region_rect = Rect2(offset_x, 0, bounds.size.x, tex.get_height())
	s.position = Vector2(bounds.position.x, top)
	parent.add_child(s)
	return s


func _add_ambient(bounds: Rect2) -> void:
	var cfg: Dictionary = AMBIENT[world]
	var p := CPUParticles2D.new()
	p.name = "Ambient"
	p.z_index = -3990
	p.amount = cfg.amount
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.position = Vector2(bounds.get_center().x, 10.0)
	p.emission_rect_extents = Vector2(bounds.size.x * 0.5, 90.0)
	p.direction = Vector2.RIGHT
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 8.0
	p.gravity = cfg.gravity
	p.color = cfg.color
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0))
	ramp.set_color(1, Color(1, 1, 1, 0))
	ramp.add_point(0.2, Color.WHITE)
	ramp.add_point(0.8, Color.WHITE)
	p.color_ramp = ramp
	if world == 3:
		p.hue_variation_min = -0.05
		p.hue_variation_max = 0.05
	add_child(p)


func _add_vignette() -> void:
	var layer := CanvasLayer.new()
	layer.name = "Vignette"
	layer.layer = 1
	var rect := TextureRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0))
	g.set_color(1, Color(0.04, 0.02, 0.08, 0.45))
	g.add_point(0.55, Color(0, 0, 0, 0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 1.05)
	tex.width = 128
	tex.height = 72
	rect.texture = tex
	layer.add_child(rect)
	add_child(layer)
