extends CharacterBody2D
signal selecion(datos)
@export var velocidad:Vector2
@export var in_phone: bool

func _physics_process(delta: float) -> void:
	move_and_slide()
	if not in_phone:
		velocity = Input.get_vector("izquierda","derecha","arriba","abajo")*velocidad


func _on_selector_seleccionado(datos: Variant) -> void:
	selecion.emit(datos)
