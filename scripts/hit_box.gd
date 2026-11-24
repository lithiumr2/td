extends Area2D
class_name HitBox

func take_damage(daño):
	if owner.has_method("daño"):
		owner.daño(daño)
