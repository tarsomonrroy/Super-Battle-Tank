class_name HealthComponent extends Node

signal on_death
signal on_damage_taken
signal on_respawn_timer_finished
signal on_invincibility_ended

@export var invencible_timer: Timer
@export var respawn_timer: Timer
@export var freeze_timer: Timer

var is_invencible: bool = false
var hitted_by_granade: bool = false

func _ready():
	invencible_timer.timeout.connect(func(): 
		is_invencible = false
		on_invincibility_ended.emit()
	)
	respawn_timer.timeout.connect(func(): on_respawn_timer_finished.emit())

func handle_hit(player_id: int, is_fatal: bool, on_boat: bool) -> void:
	if is_invencible and not is_fatal: return

	# Caso 1: Está no barco (perde barco)
	if on_boat and not is_fatal:
		SoundManager.play_sound("down_star")
		activate_invincibility(1.0)
		Global.toggle_boat(player_id, false)
		on_damage_taken.emit() # Player atualiza colisão e visual

	# Caso 2: Tem muitas estrelas (perde estrela)
	elif Global.get_stars(player_id) > 2 and not is_fatal:
		SoundManager.play_sound("down_star")
		Global.decrease_stars(player_id)
		Global.toggle_cut_tree(player_id, false)
		activate_invincibility(1.0)
		on_damage_taken.emit()

	# Caso 3: Morte
	else:
		SoundManager.play_sound("player_hitted")
		SoundManager.stop_sound("player_moving")
		
		hitted_by_granade = is_fatal # Marca se foi fatal (granada)
		
		# Lógica de vidas
		if not hitted_by_granade:
			if Global.get_lifes(player_id) > 0:
				Global.decrease_lifes(player_id)
				respawn_timer.start(0.5)
			else:
				# Aqui você pode emitir um sinal de Game Over definitivo se quiser
				pass 
		else:
			respawn_timer.start(0.5)
		
		Global.decrease_stars(player_id)
		Global.toggle_cut_tree(player_id, false)
		Global.toggle_boat(player_id, false)
		
		freeze_timer.stop()
		on_death.emit() # Player explode e some

func activate_invincibility(time: float):
	is_invencible = true
	invencible_timer.start(time)
