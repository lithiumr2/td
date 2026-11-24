class_name EventsBus extends Node2D
var actual = 1
#region signal
signal selected(datos)
signal enemy_dead(atacante)
signal round_just_end
signal round_end(nro_round)
signal init_round
signal inited_round(nro_round)
signal building_cliked(which)
signal state_changed(state,which)
#endregion
enum State {Building, Clicking}
var state: State = State.Building:
	set(new_value):
		if state == new_value: return
		else:
			state = new_value
			state_changed.emit(state,which)
			print("lol")
var which
func _ready() -> void:
	Eb.init_round.connect(_on_init_round)
	Eb.round_just_end.connect(_on_end_round)

func _on_init_round():
	var nro_round = actual 
	inited_round.emit(nro_round)

func _on_end_round():
	actual += 1

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("construir"):
		state = State.Building
	if event.is_action_pressed("tocar"):
		state = State.Clicking
