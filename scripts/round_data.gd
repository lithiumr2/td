extends Resource
class_name RoundData

@export var nro_round: int
@export var round: Array = [
	{
		"total": 10,
		"enemy": preload("res://scene/enemigo.tscn"),
		"cooldown": 2.0,
		"cooldown inicial": 0.0,
		"life multiplicator": 1.0,
		"speed multiplicator": 1.0,
		"shield multiplicator": 1.0
		}
]
