@tool
extends EditorPlugin

const MENU_ITEM_NAME := "RoundMaker: Crear nuevo nivel..."

var _dialog: Window
var _enemy_dialog: EditorFileDialog
var _load_dialog: EditorFileDialog

var _tabs: TabContainer
var _preset_option: OptionButton

var _name_input: LineEdit
var _path_input: LineEdit
var _enemy_input: LineEdit

var _rounds_spin: SpinBox
var _base_count_spin: SpinBox
var _step_count_spin: SpinBox
var _cooldown_spin: SpinBox
var _life_step_spin: SpinBox
var _speed_step_spin: SpinBox
var _shield_step_spin: SpinBox

var _edit_round_spin: SpinBox
var _round_blocks_container: VBoxContainer
var _working_rounds: Array[RoundData] = []

var _status_label: RichTextLabel
var _create_btn: Button

var _loaded_round_list: RoundList
var _loaded_path: String = ""
var _is_rebuilding: bool = false


func _enter_tree() -> void:
	add_tool_menu_item(MENU_ITEM_NAME, _open_round_maker)


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM_NAME)
	if is_instance_valid(_dialog):
		_dialog.queue_free()
	if is_instance_valid(_enemy_dialog):
		_enemy_dialog.queue_free()
	if is_instance_valid(_load_dialog):
		_load_dialog.queue_free()


func _open_round_maker() -> void:
	if not is_instance_valid(_dialog):
		_build_dialog()
	if _working_rounds.is_empty():
		_rebuild_working_rounds_from_generator()
	_validate_form()

	# Adapta la ventana al tamaño real de pantalla del editor (ideal para PC y móvil)
	var editor_size := EditorInterface.get_base_control().size
	var target_w := clampi(int(editor_size.x * 0.85), 360, 720)
	var target_h := clampi(int(editor_size.y * 0.85), 320, 660)
	_dialog.popup_centered(Vector2i(target_w, target_h))


func _build_dialog() -> void:
	_dialog = Window.new()
	_dialog.title = "RoundMaker - Creador y Editor de Niveles"
	_dialog.transient = true
	_dialog.exclusive = true
	_dialog.unresizable = false
	_dialog.min_size = Vector2i(340, 300)
	_dialog.close_requested.connect(_dialog.hide)

	var bg := PanelContainer.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dialog.add_child(bg)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	bg.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(main_vbox)

	# Barra superior compacta
	var top_actions := HBoxContainer.new()
	top_actions.add_theme_constant_override("separation", 6)
	main_vbox.add_child(top_actions)

	var load_btn := Button.new()
	load_btn.text = "Cargar .tres..."
	load_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	load_btn.pressed.connect(_open_load_picker)
	top_actions.add_child(load_btn)

	var regen_btn := Button.new()
	regen_btn.text = "Regenerar Curva"
	regen_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	regen_btn.pressed.connect(func():
		_rebuild_working_rounds_from_generator()
		_validate_form()
	)
	top_actions.add_child(regen_btn)

	# Pestañas expandibles
	_tabs = TabContainer.new()
	_tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(_tabs)

	_tabs.add_child(_build_generator_tab())
	_tabs.add_child(_build_round_inspector_tab())

	# Panel de estado compacto con scroll automático si hay varios avisos
	_status_label = RichTextLabel.new()
	_status_label.bbcode_enabled = true
	_status_label.custom_minimum_size = Vector2(0, 56)
	_status_label.scroll_active = true
	main_vbox.add_child(_status_label)

	# Botones siempre visibles al fondo
	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_END
	bottom_hbox.add_theme_constant_override("separation", 8)
	main_vbox.add_child(bottom_hbox)

	var cancel_btn := Button.new()
	cancel_btn.text = "Cancelar"
	cancel_btn.pressed.connect(_dialog.hide)
	bottom_hbox.add_child(cancel_btn)

	_create_btn = Button.new()
	_create_btn.text = "Crear / Guardar Nivel"
	_create_btn.pressed.connect(_on_create_pressed)
	bottom_hbox.add_child(_create_btn)

	EditorInterface.get_base_control().add_child(_dialog)


func _build_generator_tab() -> Control:
	# ScrollContainer para que nunca se corte en pantallas pequeñas
	var scroll := ScrollContainer.new()
	scroll.name = "Generador"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var pad := MarginContainer.new()
	pad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pad.add_theme_constant_override("margin_left", 6)
	pad.add_theme_constant_override("margin_right", 10)
	pad.add_theme_constant_override("margin_top", 6)
	pad.add_theme_constant_override("margin_bottom", 6)
	scroll.add_child(pad)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)
	pad.add_child(vbox)

	# Presets rápidos
	var preset_row := HBoxContainer.new()
	preset_row.add_theme_constant_override("separation", 6)
	vbox.add_child(preset_row)
	preset_row.add_child(_make_label("Preset:"))

	_preset_option = OptionButton.new()
	_preset_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_preset_option.add_item("Personalizado", 0)
	_preset_option.add_item("1. Oleada Tranquila", 1)
	_preset_option.add_item("2. Asalto Estándar", 2)
	_preset_option.add_item("3. Horda Frenética", 3)
	_preset_option.add_item("4. Tanques Blindados", 4)
	_preset_option.item_selected.connect(_apply_preset)
	preset_row.add_child(_preset_option)

	# Nombre del nivel
	vbox.add_child(_make_label("Nombre del nivel (ej. nivel_01):"))
	_name_input = LineEdit.new()
	_name_input.placeholder_text = "nivel_01"
	_name_input.text_changed.connect(func(_t: String): _validate_form())
	vbox.add_child(_name_input)

	# Carpeta destino
	vbox.add_child(_make_label("Carpeta destino (.tres):"))
	_path_input = LineEdit.new()
	_path_input.text = "res://resorces/niveles"
	_path_input.text_changed.connect(func(_t: String): _validate_form())
	vbox.add_child(_path_input)

	# Escena de enemigo base
	vbox.add_child(_make_label("Escena enemigo base (.tscn):"))
	var enemy_row := HBoxContainer.new()
	enemy_row.add_theme_constant_override("separation", 6)
	vbox.add_child(enemy_row)

	_enemy_input = LineEdit.new()
	_enemy_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_enemy_input.text = "res://scene/enemigo.tscn"
	_enemy_input.text_changed.connect(func(_t: String):
		_rebuild_working_rounds_from_generator()
		_validate_form()
	)
	enemy_row.add_child(_enemy_input)

	var pick_enemy_btn := Button.new()
	pick_enemy_btn.text = "Explorar..."
	pick_enemy_btn.pressed.connect(_open_enemy_picker)
	enemy_row.add_child(pick_enemy_btn)

	# Parámetros numéricos en 2 columnas bien alineadas
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 4)
	vbox.add_child(grid)

	grid.add_child(_make_expanding_label("Cantidad de rondas:"))
	_rounds_spin = _make_int_spin(10, 1, 200)
	grid.add_child(_rounds_spin)

	grid.add_child(_make_expanding_label("Enemigos ronda 1:"))
	_base_count_spin = _make_int_spin(10, 1, 999)
	grid.add_child(_base_count_spin)

	grid.add_child(_make_expanding_label("+ Enemigos / ronda:"))
	_step_count_spin = _make_int_spin(3, 0, 500)
	grid.add_child(_step_count_spin)

	grid.add_child(_make_expanding_label("Cooldown base (s):"))
	_cooldown_spin = _make_float_spin(2.0, 0.05, 30.0, 0.1)
	grid.add_child(_cooldown_spin)

	grid.add_child(_make_expanding_label("+ Vida / ronda:"))
	_life_step_spin = _make_float_spin(0.15, 0.0, 10.0, 0.05)
	grid.add_child(_life_step_spin)

	grid.add_child(_make_expanding_label("+ Velocidad / ronda:"))
	_speed_step_spin = _make_float_spin(0.03, 0.0, 5.0, 0.01)
	grid.add_child(_speed_step_spin)

	grid.add_child(_make_expanding_label("+ Escudo / ronda:"))
	_shield_step_spin = _make_float_spin(0.10, 0.0, 10.0, 0.05)
	grid.add_child(_shield_step_spin)

	return scroll


func _build_round_inspector_tab() -> Control:
	var tab_vbox := VBoxContainer.new()
	tab_vbox.name = "Editar Rondas"
	tab_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tab_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_vbox.add_theme_constant_override("separation", 6)

	var top_bar := HFlowContainer.new()
	top_bar.add_theme_constant_override("h_separation", 6)
	top_bar.add_theme_constant_override("v_separation", 4)
	tab_vbox.add_child(top_bar)

	top_bar.add_child(_make_label("Ronda:"))
	_edit_round_spin = SpinBox.new()
	_edit_round_spin.min_value = 1
	_edit_round_spin.max_value = 1
	_edit_round_spin.value_changed.connect(func(v: float): _refresh_round_blocks_ui(int(v) - 1))
	top_bar.add_child(_edit_round_spin)

	var add_block_btn := Button.new()
	add_block_btn.text = "+ Bloque"
	add_block_btn.pressed.connect(_on_add_block_to_current_round)
	top_bar.add_child(add_block_btn)

	var dup_round_btn := Button.new()
	dup_round_btn.text = "Duplicar Ronda"
	dup_round_btn.pressed.connect(_on_duplicate_current_round)
	top_bar.add_child(dup_round_btn)

	var boss_btn := Button.new()
	boss_btn.text = "+ Jefe Final"
	boss_btn.pressed.connect(_on_add_boss_to_last_round)
	top_bar.add_child(boss_btn)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_vbox.add_child(scroll)

	_round_blocks_container = VBoxContainer.new()
	_round_blocks_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_round_blocks_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_round_blocks_container)

	return tab_vbox


func _apply_preset(index: int) -> void:
	_is_rebuilding = true
	match index:
		1:
			_rounds_spin.value = 8
			_base_count_spin.value = 6
			_step_count_spin.value = 2
			_cooldown_spin.value = 2.4
			_life_step_spin.value = 0.08
			_speed_step_spin.value = 0.01
			_shield_step_spin.value = 0.0
		2:
			_rounds_spin.value = 12
			_base_count_spin.value = 10
			_step_count_spin.value = 3
			_cooldown_spin.value = 1.8
			_life_step_spin.value = 0.15
			_speed_step_spin.value = 0.03
			_shield_step_spin.value = 0.10
		3:
			_rounds_spin.value = 15
			_base_count_spin.value = 18
			_step_count_spin.value = 5
			_cooldown_spin.value = 0.9
			_life_step_spin.value = 0.10
			_speed_step_spin.value = 0.06
			_shield_step_spin.value = 0.05
		4:
			_rounds_spin.value = 10
			_base_count_spin.value = 4
			_step_count_spin.value = 1
			_cooldown_spin.value = 3.0
			_life_step_spin.value = 0.30
			_speed_step_spin.value = 0.01
			_shield_step_spin.value = 0.25
	_is_rebuilding = false
	_rebuild_working_rounds_from_generator()
	_validate_form()


func _rebuild_working_rounds_from_generator() -> void:
	if _rounds_spin == null or _is_rebuilding:
		return

	var total_rounds := int(_rounds_spin.value)
	var base_count := int(_base_count_spin.value)
	var step_count := int(_step_count_spin.value)
	var base_cooldown := float(_cooldown_spin.value)
	var life_step := float(_life_step_spin.value)
	var speed_step := float(_speed_step_spin.value)
	var shield_step := float(_shield_step_spin.value)

	var enemy_path := _enemy_input.text.strip_edges()
	var enemy_scene: PackedScene = null
	if enemy_path.begins_with("res://") and ResourceLoader.exists(enemy_path):
		enemy_scene = load(enemy_path) as PackedScene

	_working_rounds.clear()
	for i in range(total_rounds):
		var r_data := RoundData.new()
		r_data.nro_round = i + 1
		r_data.round = [{
			"total": base_count + (i * step_count),
			"enemy": enemy_scene,
			"cooldown": maxf(0.05, snappedf(base_cooldown - (i * 0.05), 0.01)),
			"cooldown inicial": 0.0,
			"life multiplicator": snappedf(1.0 + (i * life_step), 0.01),
			"speed multiplicator": snappedf(1.0 + (i * speed_step), 0.01),
			"shield multiplicator": snappedf(1.0 + (i * shield_step), 0.01)
		}]
		_working_rounds.append(r_data)

	if _edit_round_spin != null:
		_edit_round_spin.max_value = max(1, _working_rounds.size())
		_edit_round_spin.value = 1
		_refresh_round_blocks_ui(0)


func _refresh_round_blocks_ui(round_idx: int) -> void:
	if _round_blocks_container == null:
		return
	for child in _round_blocks_container.get_children():
		child.queue_free()

	if round_idx < 0 or round_idx >= _working_rounds.size():
		return

	var r_data := _working_rounds[round_idx]
	for b_idx in range(r_data.round.size()):
		var block: Dictionary = r_data.round[b_idx]
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_round_blocks_container.add_child(card)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		# Fila escena
		var scene_row := HBoxContainer.new()
		card_vbox.add_child(scene_row)
		scene_row.add_child(_make_label("Bloque " + str(b_idx + 1) + " Escena:"))

		var e_edit := LineEdit.new()
		var e_res = block.get("enemy", null)
		e_edit.text = e_res.resource_path if (e_res is Resource) else _enemy_input.text
		e_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		e_edit.text_changed.connect(func(new_p: String):
			var clean_p := new_p.strip_edges()
			if ResourceLoader.exists(clean_p):
				block["enemy"] = load(clean_p)
			else:
				block["enemy"] = null
			_validate_form()
		)
		scene_row.add_child(e_edit)

		# Grid compacto de 2 columnas para que quepa en cualquier pantalla
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(grid)

		grid.add_child(_make_expanding_label("Total:"))
		var tot_sb := _make_raw_int_spin(int(block.get("total", 10)), 1, 999)
		tot_sb.value_changed.connect(func(v: float):
			block["total"] = int(v)
			_validate_form()
		)
		grid.add_child(tot_sb)

		grid.add_child(_make_expanding_label("Cooldown (s):"))
		var cd_sb := _make_raw_float_spin(float(block.get("cooldown", 2.0)), 0.01, 60.0, 0.05)
		cd_sb.value_changed.connect(func(v: float):
			block["cooldown"] = v
			_validate_form()
		)
		grid.add_child(cd_sb)

		grid.add_child(_make_expanding_label("CD Inicial (s):"))
		var init_sb := _make_raw_float_spin(float(block.get("cooldown inicial", 0.0)), 0.0, 120.0, 0.25)
		init_sb.value_changed.connect(func(v: float):
			block["cooldown inicial"] = v
			_validate_form()
		)
		grid.add_child(init_sb)

		grid.add_child(_make_expanding_label("Vida x:"))
		var life_sb := _make_raw_float_spin(float(block.get("life multiplicator", 1.0)), 0.1, 100.0, 0.05)
		life_sb.value_changed.connect(func(v: float): block["life multiplicator"] = v)
		grid.add_child(life_sb)

		grid.add_child(_make_expanding_label("Velocidad x:"))
		var spd_sb := _make_raw_float_spin(float(block.get("speed multiplicator", 1.0)), 0.1, 20.0, 0.05)
		spd_sb.value_changed.connect(func(v: float): block["speed multiplicator"] = v)
		grid.add_child(spd_sb)

		grid.add_child(_make_expanding_label("Escudo x:"))
		var shd_sb := _make_raw_float_spin(float(block.get("shield multiplicator", 1.0)), 0.0, 100.0, 0.05)
		shd_sb.value_changed.connect(func(v: float): block["shield multiplicator"] = v)
		grid.add_child(shd_sb)

		var del_btn := Button.new()
		del_btn.text = "Quitar este bloque"
		del_btn.disabled = (r_data.round.size() <= 1)
		del_btn.pressed.connect(func():
			if b_idx < r_data.round.size():
				r_data.round.remove_at(b_idx)
				_refresh_round_blocks_ui(round_idx)
				_validate_form()
		)
		card_vbox.add_child(del_btn)


func _on_add_block_to_current_round() -> void:
	var idx := int(_edit_round_spin.value) - 1
	if idx < 0 or idx >= _working_rounds.size():
		return
	var enemy_scene: PackedScene = null
	var p := _enemy_input.text.strip_edges()
	if ResourceLoader.exists(p):
		enemy_scene = load(p) as PackedScene
	_working_rounds[idx].round.append({
		"total": 5,
		"enemy": enemy_scene,
		"cooldown": 1.5,
		"cooldown inicial": 2.0,
		"life multiplicator": 1.0,
		"speed multiplicator": 1.0,
		"shield multiplicator": 1.0
	})
	_refresh_round_blocks_ui(idx)
	_validate_form()


func _on_duplicate_current_round() -> void:
	var idx := int(_edit_round_spin.value) - 1
	if idx < 0 or idx >= _working_rounds.size():
		return
	var clone_round := RoundData.new()
	clone_round.round = _working_rounds[idx].round.duplicate(true)
	_working_rounds.insert(idx + 1, clone_round)
	for i in range(_working_rounds.size()):
		_working_rounds[i].nro_round = i + 1
	_edit_round_spin.max_value = _working_rounds.size()
	_edit_round_spin.value = idx + 2
	_validate_form()


func _on_add_boss_to_last_round() -> void:
	if _working_rounds.is_empty():
		return
	var last_idx := _working_rounds.size() - 1
	var enemy_scene: PackedScene = null
	var p := _enemy_input.text.strip_edges()
	if ResourceLoader.exists(p):
		enemy_scene = load(p) as PackedScene
	_working_rounds[last_idx].round.append({
		"total": 1,
		"enemy": enemy_scene,
		"cooldown": 2.0,
		"cooldown inicial": 4.0,
		"life multiplicator": 5.0,
		"speed multiplicator": 0.85,
		"shield multiplicator": 4.0
	})
	_edit_round_spin.value = last_idx + 1
	_refresh_round_blocks_ui(last_idx)
	_validate_form()


func _make_label(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	return lbl


func _make_expanding_label(txt: String) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return lbl


func _make_int_spin(default_val: int, min_val: int, max_val: int) -> SpinBox:
	var sb := _make_raw_int_spin(default_val, min_val, max_val)
	sb.value_changed.connect(func(_v: float):
		_rebuild_working_rounds_from_generator()
		_validate_form()
	)
	return sb


func _make_float_spin(default_val: float, min_val: float, max_val: float, step_val: float) -> SpinBox:
	var sb := _make_raw_float_spin(default_val, min_val, max_val, step_val)
	sb.value_changed.connect(func(_v: float):
		_rebuild_working_rounds_from_generator()
		_validate_form()
	)
	return sb


func _make_raw_int_spin(default_val: int, min_val: int, max_val: int) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = 1
	sb.value = default_val
	return sb


func _make_raw_float_spin(default_val: float, min_val: float, max_val: float, step_val: float) -> SpinBox:
	var sb := SpinBox.new()
	sb.min_value = min_val
	sb.max_value = max_val
	sb.step = step_val
	sb.value = default_val
	return sb


func _open_enemy_picker() -> void:
	if not is_instance_valid(_enemy_dialog):
		_enemy_dialog = EditorFileDialog.new()
		_enemy_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_enemy_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_enemy_dialog.filters = PackedStringArray(["*.tscn ; Escenas de Godot"])
		_enemy_dialog.file_selected.connect(func(path: String):
			_enemy_input.text = path
			_rebuild_working_rounds_from_generator()
			_validate_form()
		)
		EditorInterface.get_base_control().add_child(_enemy_dialog)
	_enemy_dialog.popup_centered_ratio(0.7)


func _open_load_picker() -> void:
	if not is_instance_valid(_load_dialog):
		_load_dialog = EditorFileDialog.new()
		_load_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
		_load_dialog.access = EditorFileDialog.ACCESS_RESOURCES
		_load_dialog.filters = PackedStringArray(["*.tres ; Recursos RoundList"])
		_load_dialog.file_selected.connect(_on_existing_round_list_selected)
		EditorInterface.get_base_control().add_child(_load_dialog)
	_load_dialog.popup_centered_ratio(0.7)


func _on_existing_round_list_selected(path: String) -> void:
	var res := load(path)
	if not (res is RoundList):
		_status_label.text = "[color=#ff6b6b]• El archivo seleccionado no es un RoundList válido.[/color]"
		return

	_loaded_round_list = res as RoundList
	_loaded_path = path
	_path_input.text = path.get_base_dir()
	_name_input.text = path.get_file().get_basename()

	_working_rounds.clear()
	for r in _loaded_round_list.rounds:
		if r != null:
			var copy_r := RoundData.new()
			copy_r.nro_round = r.nro_round
			copy_r.round = r.round.duplicate(true)
			_working_rounds.append(copy_r)

	_is_rebuilding = true
	_rounds_spin.value = max(1, _working_rounds.size())
	_is_rebuilding = false

	_edit_round_spin.max_value = max(1, _working_rounds.size())
	_edit_round_spin.value = 1
	_refresh_round_blocks_ui(0)
	_validate_form()


func _validate_form() -> bool:
	if _status_label == null or _create_btn == null:
		return false

	var errors: Array[String] = []
	var warnings: Array[String] = []

	var level_name := _name_input.text.strip_edges()
	var folder_path := _path_input.text.strip_edges()
	var enemy_path := _enemy_input.text.strip_edges()

	if level_name.is_empty():
		errors.append("Falta el nombre del nivel.")
	elif level_name.contains("/") or level_name.contains("\\"):
		errors.append("El nombre del nivel no debe llevar barras.")

	if not folder_path.begins_with("res://"):
		errors.append("La carpeta destino debe empezar con res://")

	if not enemy_path.begins_with("res://") or not ResourceLoader.exists(enemy_path):
		errors.append("La escena de enemigo base no existe en: " + enemy_path)

	var target_file := folder_path.path_join(level_name + ".tres")
	var is_editing_same_file := (target_file == _loaded_path and _loaded_round_list != null)
	if not level_name.is_empty() and ResourceLoader.exists(target_file) and not is_editing_same_file:
		errors.append("Ya existe un archivo en: " + target_file)

	var total_enemies := 0
	var est_seconds := 0.0
	for r in _working_rounds:
		for blk in r.round:
			var t := int(blk.get("total", 0))
			var cd := float(blk.get("cooldown", 0.0))
			var init_cd := float(blk.get("cooldown inicial", 0.0))
			var e_val = blk.get("enemy", null)
			total_enemies += maxi(0, t)
			est_seconds += maxf(0.0, init_cd) + (maxi(0, t) * maxf(0.0, cd))

			if t <= 0:
				errors.append("Ronda " + str(r.nro_round) + " tiene un bloque con total <= 0.")
			if e_val == null:
				warnings.append("Ronda " + str(r.nro_round) + " tiene un bloque sin escena asignada.")
			if cd < 0.15:
				warnings.append("Ronda " + str(r.nro_round) + " tiene cooldown muy bajo (" + str(cd) + "s).")

	if not errors.is_empty():
		var msg := ""
		for err in errors:
			msg += "[color=#ff6b6b]• " + err + "[/color]\n"
		_status_label.text = msg.strip_edges()
		_create_btn.disabled = true
		return false

	var action_txt := "Sobrescribir: " if is_editing_same_file else "Crear: "
	var out := "[color=#6ee77a]• Listo -> " + action_txt + target_file + "[/color]\n"
	out += "[color=#9bd5ff]Rondas: " + str(_working_rounds.size()) + " | Enemigos: " + str(total_enemies) + " | Duración: ~" + str(snappedf(est_seconds, 0.1)) + "s[/color]"
	for w in warnings:
		out += "\n[color=#ffd166]⚠ " + w + "[/color]"

	_status_label.text = out
	_create_btn.disabled = false
	return true


func _on_create_pressed() -> void:
	if not _validate_form():
		return

	var level_name := _name_input.text.strip_edges()
	var folder_path := _path_input.text.strip_edges()

	if not DirAccess.dir_exists_absolute(folder_path):
		var mk_err := DirAccess.make_dir_recursive_absolute(folder_path)
		if mk_err != OK:
			_status_label.text = "[color=#ff6b6b]• No se pudo crear la carpeta: " + folder_path + "[/color]"
			return

	var save_path := folder_path.path_join(level_name + ".tres")
	var is_editing_same_file := (save_path == _loaded_path and _loaded_round_list != null)
	var round_list := _loaded_round_list if is_editing_same_file else RoundList.new()

	var final_rounds: Array[RoundData] = []
	for i in range(_working_rounds.size()):
		var src := _working_rounds[i]
		var dst := RoundData.new()
		dst.nro_round = i + 1
		dst.round = src.round.duplicate(true)
		final_rounds.append(dst)

	round_list.rounds = final_rounds

	var save_err := ResourceSaver.save(round_list, save_path)
	if save_err != OK:
		_status_label.text = "[color=#ff6b6b]• Error al guardar en: " + save_path + "[/color]"
		return

	_loaded_round_list = round_list
	_loaded_path = save_path

	EditorInterface.get_resource_filesystem().scan()
	EditorInterface.select_file(save_path)
	EditorInterface.inspect_object(round_list)

	print("[RoundMaker] Nivel guardado en: ", save_path, " (", final_rounds.size(), " rondas)")
	_dialog.hide()
