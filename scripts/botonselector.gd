extends Button
class_name BotonSelector
@export var datos: TurretData

var instance
var grid_manager: GridManager

func _process(delta: float) -> void:
	if not is_instance_valid(instance): return
	else: move_instance()

func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	text = datos.name
	icon=datos.texture
	grid_manager = get_tree().current_scene.find_child("GridManager", true, false)

func _on_button_down() -> void:
	instance = datos.scene.instantiate()
	add_child(instance)
	

func _on_button_up() -> void:
	var dentro = owner.menu.get_global_rect().has_point(get_global_mouse_position())
	if dentro == false:
		if is_instance_valid(grid_manager):
			grid_manager.place_building(grid_manager.world_to_grid(grid_manager.get_global_mouse_position()), datos)
	for node in get_children():
		if node is torreta: node.queue_free()

func move_instance():
	instance.global_position = get_global_mouse_position()
