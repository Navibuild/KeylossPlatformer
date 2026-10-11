extends Label
## Types the label's text out, letter by letter.

## Fraction of the text revealed per second.
@export var speed := 0.3
## Seconds to wait before starting.
@export var delay := 0.0

var _time := 0.0


func _ready() -> void:
	self.visible_ratio = 0


func _process(delta: float) -> void:
	_time += delta
	if _time < delay:
		return
	self.visible_ratio = minf(1.0, self.visible_ratio + speed * delta)
	if self.visible_ratio >= 1.0:
		set_process(false)
