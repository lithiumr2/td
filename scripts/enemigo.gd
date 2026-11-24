extends CharacterBody2D
class_name enemigo

@export var velocidad := 150
@export var vida_max: int = 100
var vida: int = vida_max
var atacante

func _physics_process(delta: float) -> void:
	var closest = _find_closest()
	move_to_base(closest)
	move_and_slide()

func _ready() -> void:
	add_to_group("enemigos")
	_find_closest()

@warning_ignore("shadowed_variable")
func daño(daño):
	vida -= daño
	if vida <= 0:
		if is_instance_valid(atacante): Eb.enemy_dead.emit(atacante)
		queue_free()

func _find_closest():
	var closest: base
	var distancia: float = 99999999.0
	var bases = get_tree().get_nodes_in_group("base")
	
	for nodo  in bases:
		var distancia_act = self.global_position.distance_to(nodo.global_position)
		
		if distancia > distancia_act:
			distancia = distancia_act
			closest = nodo
	return closest

func move_to_base(closest) -> void:
	if closest == null:
		return
	var dis: Vector2 = closest.global_position - self.global_position
	if abs(dis) < Vector2(1, 1):
		velocity = Vector2.ZERO
		return
	if dis.x < dis.y:
		velocity.x = velocidad if dis.x > 0 else -velocidad
		velocity.y = 0.0
	else:
		velocity.y = velocidad if dis.y > 0 else -velocidad
		velocity.x = 0.0
