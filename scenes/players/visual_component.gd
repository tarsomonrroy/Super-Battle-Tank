class_name VisualComponent extends Node

@export var sprite: AnimatedSprite2D
@export var boat: Sprite2D
@export var spawn_anim: AnimatedSprite2D
@export var invencible_anim: AnimatedSprite2D
@export var flick_animation: AnimationPlayer

const MAT_P1 = preload("res://shaders_material/player_one_shader_material.tres")
const MAT_P2 = preload("res://shaders_material/player_two_shader_material.tres")
const MAT_P3 = preload("res://shaders_material/player_three_shader_material.tres")
const MAT_P4 = preload("res://shaders_material/player_four_shader_material.tres")

var cur_state: String = "up"

func setup_palette(player_id: int):
	sprite.material = Material.new()
	match player_id:
		1: sprite.material = MAT_P1
		2: sprite.material = MAT_P2
		3: sprite.material = MAT_P3
		4: sprite.material = MAT_P4

func play_spawn_sequence():
	spawn_anim.visible = true
	spawn_anim.play("spawn")
	sprite.visible = false
	boat.visible = false

func finish_spawn_sequence(player_id: int, on_boat: bool):
	spawn_anim.visible = false
	sprite.visible = true
	toggle_boat(on_boat)
	update_idle(player_id)

func update_movement_visuals(input: Vector2, player_id: int):
	# Rotação do Barco
	if input.y == -1: boat.rotation_degrees = 0.0
	elif input.y == 1: boat.rotation_degrees = 180.0
	elif input.x == -1: boat.rotation_degrees = -90.0
	elif input.x == 1: boat.rotation_degrees = 90.0

	# Direção da Animação
	var new_state: String
	if abs(input.x) > abs(input.y):
		new_state = "right" if input.x > 0 else "left"
	else:
		new_state = "down" if input.y > 0 else "up"

	if new_state != cur_state or not sprite.is_playing():
		cur_state = new_state
		var anim_suffix = _stars_to_anim(player_id)
		sprite.play(cur_state + "_" + anim_suffix)

func update_idle(player_id: int):
	sprite.pause()
	# Garante que o frame correto (baseado nas estrelas) esteja aparecendo mesmo parado
	var anim_suffix = _stars_to_anim(player_id)
	if sprite.animation != cur_state + "_" + anim_suffix:
		sprite.play(cur_state + "_" + anim_suffix)
		sprite.pause()

func toggle_boat(enable: bool):
	boat.visible = enable

func toggle_invincibility_visual(enable: bool):
	invencible_anim.visible = enable
	if enable:
		invencible_anim.play("invencible")
	else:
		invencible_anim.stop()

func toggle_freeze_flick(enable: bool):
	if enable:
		flick_animation.play("flick")
	else:
		flick_animation.play("visible")

func hide_player():
	sprite.visible = false
	boat.visible = false
	invencible_anim.visible = false

func _stars_to_anim(player_id: int) -> String:
	var state = Global.get_stars(player_id)
	if state >= 5: return "4"
	return str(state)
