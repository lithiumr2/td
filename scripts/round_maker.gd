@tool
class_name RoundMaker
extends Resource

@export var rondas: Array[RoundData] = []

@export_group("Generador Automático")
@export var total_rondas_a_crear: int = 10
@export var enemigo_base: PackedScene
@export var enemigos_iniciales: int = 5
@export var incremento_enemigos_por_ronda: int = 3
@export var intervalo_base: float = 1.2
@export var reduccion_intervalo: float = 0.05
@export var intervalo_minimo: float = 0.25

@export_tool_button("Generar Rondas", "Add") var btn_generar = generar_rondas
@export_tool_button("Limpiar Rondas", "Remove") var btn_limpiar = limpiar_rondas

func generar_rondas() -> void:
	if not Engine.is_editor_hint():
		return
		
	rondas.clear()
	
	for i in range(total_rondas_a_crear):
		var nueva_ronda := RoundData.new()
		nueva_ronda.numero_ronda = i + 1
		nueva_ronda.escena_enemigo = enemigo_base
		nueva_ronda.cantidad_enemigos = enemigos_iniciales + (i * incremento_enemigos_por_ronda)
		nueva_ronda.intervalo_spawn = max(intervalo_minimo, intervalo_base - (i * reduccion_intervalo))
		nueva_ronda.recompensa_ronda = 50 + (i * 15)
		
		rondas.append(nueva_ronda)
	
	# Notifica al editor que el recurso cambió para que puedas guardarlo (Ctrl+S)
	emit_changed()
	print("Se generaron ", rondas.size(), " rondas correctamente.")

func limpiar_rondas() -> void:
	if not Engine.is_editor_hint():
		return
	rondas.clear()
	emit_changed()
