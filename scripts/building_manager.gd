class_name BuildController
extends Node2D

#region

@export var grid_manager: GridManager
var data

#endregion

func _ready() -> void:
	Eb.selected.connect(_on_jugador_selecion)

func _unhandled_input(event: InputEvent) -> void:
	if not grid_manager: return

	if Eb.state == Eb.State.Building:
		# Si hacemos clic con el botón izquierdo -> Construir
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if data:
				var mouse_pos: Vector2 = get_global_mouse_position()
				var cell: Vector2i = grid_manager.world_to_grid(mouse_pos)
				
				# Llamamos a la función limpia del GridManager
				grid_manager.place_building(cell, data)

		# Si hacemos clic con el botón derecho -> Demoler
		elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var cell: Vector2i = grid_manager.world_to_grid(mouse_pos)
			
			# Llamamos a la función de borrado del GridManager
			grid_manager.remove_building_at(cell)
	
	if Eb.state == Eb.State.Clicking:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var cell: Vector2i = grid_manager.world_to_grid(mouse_pos)
			var which = get_parent().get_building_at(cell)
			Eb.building_cliked.emit(which)

func _on_jugador_selecion(datos: Variant) -> void:
	data=datos
