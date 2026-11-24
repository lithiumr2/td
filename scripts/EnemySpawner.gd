extends Node2D
class_name EnemyBase

# Exportamos el recurso (aquí arrastras tu archivo round1.tres desde el Inspector)
@export var nivel: RoundList

# Nodo opcional donde se instanciarán los enemigos (si está vacío, se añaden a la escena principal)
@export var contenedor_enemigos: Node2D = self

func _ready() -> void:
	Eb.inited_round.connect(_on_inited_round)

func _on_inited_round(nro_round: int) -> void:
	if nivel:
		var indice_ronda: int = nro_round - 1
		if indice_ronda >= 0 and indice_ronda < nivel.rounds.size():
			var datos_ronda = nivel.rounds[indice_ronda]
			iniciar_ronda(datos_ronda)
	else:
		print_debug("¡Falta asignar el recurso de la ronda en el Inspector!")

func iniciar_ronda(datos_ronda) -> void:
	# Recorremos cada configuración del arreglo 'round'
	for grupo_enemigo in datos_ronda.round:
		var total = grupo_enemigo["total"]
		var escena_enemigo = grupo_enemigo["enemy"]
		var cooldown_inicial = grupo_enemigo["cooldown inicial"]
		var cooldown = grupo_enemigo["cooldown"]
		
		var life_mult = grupo_enemigo["life multiplicator"]
		var speed_mult = grupo_enemigo["speed multiplicator"]
		var shield_mult = grupo_enemigo["shield multiplicator"]
		
		# Si hay un cooldown inicial configurado, esperamos antes del primer enemigo de este grupo
		if cooldown_inicial > 0:
			await get_tree().create_timer(cooldown_inicial).timeout
		
		# Bucle para generar la cantidad exacta de enemigos de este tipo
		for i in range(total):
			if escena_enemigo:
				# 1. Instanciamos la escena del enemigo
				var enemigo_instancia = escena_enemigo.instantiate()
				
				# 2. Aplicamos los multiplicadores si tu script de enemigo los soporta
				# (Asegúrate de que tus variables en el enemigo se llamen así o ajústalas)
				if "life" in enemigo_instancia:
					enemigo_instancia.life *= life_mult
				if "speed" in enemigo_instancia:
					enemigo_instancia.speed *= speed_mult
				if "shield" in enemigo_instancia:
					enemigo_instancia.shield *= shield_mult
				
				# 3. Añadimos el enemigo al juego
				if contenedor_enemigos:
					contenedor_enemigos.add_child(enemigo_instancia)
				else:
					get_tree().current_scene.add_child(enemigo_instancia)
			
			# Esperamos el tiempo del cooldown antes de generar el siguiente enemigo
			if cooldown > 0:
				await get_tree().create_timer(cooldown).timeout
				
	Eb.round_just_end.emit()
