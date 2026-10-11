extends Label

func _ready() -> void:
	self.visible_ratio = 0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	self.visible_ratio += 0.005
