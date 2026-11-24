extends Area2D
class_name AlcanzeCPN

var enemigos_en_rango: Array = []

enum find {closest, closest_to_base, fardest}
var who: find = find.closest
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@export var rango : float = 200
func _ready() -> void:
	if not area_entered.is_connected(_on_rango_area_entered):
		area_entered.connect(_on_rango_area_entered)
	if not area_exited.is_connected(_on_rango_area_exited):
		area_exited.connect(_on_rango_area_exited)
	
	if not (collision_shape_2d.shape is CircleShape2D):
		var nuevo_circulo := CircleShape2D.new()
		nuevo_circulo.radius = rango
		collision_shape_2d.shape = nuevo_circulo
	else:
		collision_shape_2d.shape.radius = rango

func _on_rango_area_entered(area: Node2D) -> void:
	if area.owner.is_in_group("enemigos") and area not in enemigos_en_rango and is_instance_valid(area):
		enemigos_en_rango.append(area)

func _on_rango_area_exited(area: Node2D) -> void:
	if not is_instance_valid(area):
		return

	# Si el enemigo ya se está destruyendo o no tiene owner válido, igual lo sacamos de la lista
	if not is_instance_valid(area.owner):
		enemigos_en_rango.erase(area)
		return

	if area.owner.is_in_group("enemigos"):
		enemigos_en_rango.erase(area)

func _clean_invalid() -> void:
	for i in range(enemigos_en_rango.size() - 1, -1, -1):
		if not is_instance_valid(enemigos_en_rango[i]):
			enemigos_en_rango.remove_at(i)

func find_enemy():
	_clean_invalid()
	var target = null

	if who == find.closest:
		target = find_closest()
	elif who == find.closest_to_base:
		target = find_closest_to_base()
	elif who == find.fardest:
		target = find_farthest()

	return target

func find_closest() -> Node2D:
	if enemigos_en_rango.is_empty():
		return null

	var candidato_mas_cercano: Node2D = null
	var distancia_minima: float = 999999.0

	for enemigos in enemigos_en_rango:
		if not is_instance_valid(enemigos):
			continue

		var distancia_actual = global_position.distance_to(enemigos.global_position)
		if distancia_actual < distancia_minima:
			distancia_minima = distancia_actual
			candidato_mas_cercano = enemigos

	return candidato_mas_cercano

func find_closest_to_base():
	if enemigos_en_rango.is_empty():
		return null

	var base_cercana = _find_closest_base()
	if base_cercana == null or not is_instance_valid(base_cercana):
		return find_closest()

	var candidato_mas_cercano_a_la_base: Node2D = null
	var distancia_minima: float = 999999.0

	for enemigos in enemigos_en_rango:
		if not is_instance_valid(enemigos):
			continue

		var distancia_actual = base_cercana.global_position.distance_to(enemigos.global_position)
		if distancia_actual < distancia_minima:
			distancia_minima = distancia_actual
			candidato_mas_cercano_a_la_base = enemigos

	return candidato_mas_cercano_a_la_base

func find_farthest() -> Node2D:
	if enemigos_en_rango.is_empty():
		return null

	var candidato_mas_lejano: Node2D = null
	var distancia_maxima: float = 0.0

	for enemigos in enemigos_en_rango:
		if not is_instance_valid(enemigos):
			continue

		var distancia_actual = global_position.distance_to(enemigos.global_position)
		if distancia_actual > distancia_maxima:
			distancia_maxima = distancia_actual
			candidato_mas_lejano = enemigos

	return candidato_mas_lejano

func _find_closest_base():
	var closest_base = null
	var distancia: float = 99999999.0
	var bases = get_tree().get_nodes_in_group("base")

	for nodo in bases:
		if not is_instance_valid(nodo):
			continue

		var distancia_act = self.global_position.distance_to(nodo.global_position)
		if distancia > distancia_act:
			distancia = distancia_act
			closest_base = nodo

	return closest_base
