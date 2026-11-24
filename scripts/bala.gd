extends CharacterBody2D
var origen
func _process(delta: float) -> void:
	move_and_slide()

func _autodestruccion() -> void:
	self.queue_free()
