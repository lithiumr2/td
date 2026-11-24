extends Node2D
class_name torreta

#region varables
@export var bala: PackedScene
@export_file_path var resource : String

@export_group("caracteristicas")
@export var Intervaluo := 2.0
@export var bullet_speed := 600.0
@export var cannons_amunt := 1

@export_group("tipo")
@export var all_at_time : bool = true
@export var rafagas: bool
@export var secuencial: bool

@onready var Alcanze: AlcanzeCPN = $AlcanzeCPN
@onready var area = $AlcanzeCPN/CollisionShape2D
@onready var canon1 = $Sprite2D/canon1
@onready var canon2 = $Sprite2D/canon2
@onready var canon3 = $Sprite2D/canon3
@onready var canon4 = $Sprite2D/canon4
@onready var sprite_2d: Sprite2D = $Sprite2D

var kills:int = 0
var progreso := 0.0
var canons:Array = []

#endregion

func _ready() -> void:
	#region
	if is_instance_valid(canon1): canons.insert(0,canon1)
	if is_instance_valid(canon2): canons.insert(1,canon2)
	if is_instance_valid(canon3): canons.insert(2,canon3)
	if is_instance_valid(canon4): canons.insert(3,canon4)
	#endregion
	if not Eb.enemy_dead.is_connected(_on_enemy_dead): Eb.enemy_dead.connect(_on_enemy_dead)

func _on_enemy_dead(atacante):
	if atacante == self:
		kills += 1

func _process(delta: float) -> void:
	var target = Alcanze.find_enemy()
	if is_instance_valid(target):
		var angulo_objetivo: float = (target.global_position - sprite_2d.global_position).angle() + (PI / 2.0)
		sprite_2d.rotation = angulo_objetivo
		
		progreso += delta

		if progreso >= Intervaluo:
			disparar(delta, target)
			progreso = 0.0
	else:
		progreso = 0.0

func disparar(delta: float, target: Node2D) -> void:
	if bala == null or target == null or not is_instance_valid(target): return
	
	if all_at_time:
		var cantidad := maxi(0, cannons_amunt)
		for canon in canons.slice(0,cantidad):
			if not is_instance_valid(canon): continue

			var disparo = bala.instantiate()
			get_tree().current_scene.add_child(disparo)
			disparo.global_position = canon.global_position
			disparo.rotation = sprite_2d.rotation - (PI/2)
			if "origen" in disparo:
				disparo.origen = self

			var direccion: Vector2 = (target.global_position - sprite_2d.global_position).normalized()
			disparo.velocity = direccion * bullet_speed
