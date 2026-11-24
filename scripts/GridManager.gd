class_name GridManager
extends Node2D

@export var tile_size: int = 32
@export var terrain_layer: TileMapLayer # Arrastra aquí tu TileMapLayer desde el panel de escena

var grid_buildings: Dictionary = {}

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(floor(world_pos.x / tile_size), floor(world_pos.y / tile_size))

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)

func can_place_building(cell: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var check_cell: Vector2i = cell + Vector2i(x, y)
			
			# 1. ¿Ya hay otro edificio en esta celda?
			if grid_buildings.has(check_cell):
				return false
				
			# 2. ¿Hay un tile pintado en el TileMapLayer? (-1 significa celda vacía)[span_2](start_span)[span_2](end_span)
			if terrain_layer and terrain_layer.get_cell_source_id(check_cell) != -1:
				return false
	return true

func place_building(cell: Vector2i, building_data) -> Node2D:
	if not can_place_building(cell, building_data.size):
		return null
		
	if not building_data.scene:
		return null

	var building_instance: Node2D = building_data.scene.instantiate() as Node2D
	building_instance.global_position = grid_to_world(cell)
	add_child(building_instance)

	for x in range(building_data.size.x):
		for y in range(building_data.size.y):
			grid_buildings[cell + Vector2i(x, y)] = building_instance

	return building_instance

func remove_building_at(cell: Vector2i) -> void:
	if not grid_buildings.has(cell):
		return
		
	var instance_to_remove: Node2D = grid_buildings[cell]
	var cells_to_erase: Array[Vector2i] = []

	for c in grid_buildings.keys():
		if grid_buildings[c] == instance_to_remove:
			cells_to_erase.append(c)

	for c in cells_to_erase:
		grid_buildings.erase(c)

	if is_instance_valid(instance_to_remove):
		instance_to_remove.queue_free()

func get_building_at(cell: Vector2i) -> Node2D:
	if grid_buildings.has(cell):
		return grid_buildings[cell]
	return null
