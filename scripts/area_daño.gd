extends Area2D
class_name AreaDaño

@export var daño: int=10

func _init() -> void:
	collision_mask = 4


func _on_area_entered(hitbox: Area2D):
	if hitbox is not HitBox:
		return
	
	if hitbox.owner.has_method("daño"): hitbox.owner.daño(daño)
	if "atacante" in hitbox.owner: hitbox.owner.atacante = owner.origen
