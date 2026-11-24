extends CanvasLayer

@onready var menu: Panel = $Menu

var dentro: bool = false


func _ready() -> void:
	if not Eb.state_changed.is_connected(state_changed):
		Eb.state_changed.connect(state_changed)
	if not Eb.building_cliked.is_connected(building_cliked):
		Eb.building_cliked.connect(building_cliked)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not menu.visible:
			return
		dentro = menu.get_global_rect().has_point(event.global_position)
		if not dentro:
			pass


func state_changed(_state: Eb.State, which) -> void:
	change_menu(which)


func building_cliked(which) -> void:
	change_menu(which)


func change_menu(which) -> void:
	var data: Resource = null
	var has_valid_target := is_instance_valid(which)

	if has_valid_target and "resorse" in which and which.resorse != null:
		data = which.resorse if which.resorse is Resource else load(which.resorse)

	var all_menu_nodes: Array[Node] = []
	_collect_descendants(menu, all_menu_nodes)

	if Eb.state == Eb.State.Building:
		for node in all_menu_nodes:
			if node.is_in_group("construcion"):
				_set_node_active(node, true)
			elif node.is_in_group("datos"):
				_set_node_active(node, false)

	elif Eb.state == Eb.State.Clicking:
		for node in all_menu_nodes:
			if node.is_in_group("construcion"):
				_set_node_active(node, false)
			elif node.is_in_group("datos"):
				var show_stats := has_valid_target and data is TurretData
				_set_node_active(node, show_stats)
				if show_stats:
					_apply_turret_data(node, data as TurretData, which)


func _collect_descendants(root: Node, out: Array[Node]) -> void:
	for child in root.get_children():
		out.append(child)
		_collect_descendants(child, out)


func _set_node_active(node: Node, active: bool) -> void:
	if node is CanvasItem:
		node.visible = active
	if node is BaseButton:
		node.disabled = not active


func _apply_turret_data(node: Node, turret_data: TurretData, which) -> void:
	if node is Label:
		match node.name:
			"Name":
				node.text = turret_data.name
			"Description":
				node.text = turret_data.description
			"KillsCounter":
				if "Kills" in which:
					node.text = str(which.Kills)
	elif node is TextureRect and node.name == "Image":
		node.texture = turret_data.texture
