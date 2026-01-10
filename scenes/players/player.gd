extends CharacterBody2D

@export var player_id: int = 1
@export var spawn_position: Vector2 = Vector2(136.0, 216.0)

@onready var movement_component: Node = $MovementComponent
@onready var weapon_component: Node = $WeaponComponent

@onready var level: Node2D = $".."
@onready var terrain_layer: TileMapLayer = $"../Terrain"

@onready var collision: CollisionShape2D = $Collision

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var invencible: AnimatedSprite2D = $Invencible
@onready var spawn: AnimatedSprite2D = $Spawn
@onready var boat: Sprite2D = $Boat

@onready var player_spawn_area: Area2D = $PlayerSpawnArea
@onready var player_area: Area2D = $PlayerArea

@onready var invencible_timer: Timer = $InvencibleTimer
@onready var respawn_timer: Timer = $RespawnTimer

@onready var freeze_player_timer: Timer = $FreezePlayerTimer
@onready var flick_animation: AnimationPlayer = $FlickAnimation

const TILE_SIZE = 8.0

var operating = false
var is_invencible = false

var cur_state: String = "up"
var is_on_ice: bool = false
var is_on_water: bool = false
var is_frozen: bool = false
var check_blocked: bool = true
var hitted_by_granade: bool = false

var normal_friction: float = 2000.0
var ice_friction: float = 100.0
var on_boat: bool = false

var shot_speed: float = 0.1
var max_bullets: int = 1

var BULLET_SCENE = preload("res://scenes/bullets/bullet.tscn")
var active_bullets: Array[Node2D] = []

var EXPLOSION_SCENE = preload("res://scenes/bullets/explosion.tscn")

func _ready() -> void:
	movement_component.actor = self

func generate_player():
	spawn_player()

func _process(delta: float) -> void:
	weapon_component.process_cooldown(delta)
	if not check_blocked:
		check_collisions()

func _physics_process(delta: float):
	if not operating or Global.in_game_over:
		sprite.pause()
		return
	
	var input_vector = Vector2.ZERO
	if not is_frozen:
		input_vector = get_input_vector()

	check_floor_type()

	var bonus_speed = 0.0
	if Global.get_cut_tree_state(player_id): bonus_speed += 5.0
	if Global.get_stars(player_id) == 5: bonus_speed += 5.0

	movement_component.handle_movement(input_vector, delta, bonus_speed)

	if input_vector != Vector2.ZERO:
		update_rotation_and_animation(input_vector)
		handle_move_sound()
	else:
		sprite.pause()
		SoundManager.stop_sound("player_moving")

	handle_shooting()

	var is_up_r = Input.is_action_just_released("game" + str(player_id) + "_up")
	var is_down_r = Input.is_action_just_released("game" + str(player_id) + "_down")
	var is_left_r = Input.is_action_just_released("game" + str(player_id) + "_left")
	var is_right_r = Input.is_action_just_released("game" + str(player_id) + "_right")
	if is_up_r or is_down_r or is_left_r or is_right_r:
		if is_on_ice:
			SoundManager.play_sound("ice_slide")

	move_and_slide()

func get_input_vector() -> Vector2:
	var vec = Vector2.ZERO
	if Input.is_action_pressed("game" + str(player_id) + "_up"): vec.y = -1
	elif Input.is_action_pressed("game" + str(player_id) + "_down"): vec.y = 1
	elif Input.is_action_pressed("game" + str(player_id) + "_left"): vec.x = -1
	elif Input.is_action_pressed("game" + str(player_id) + "_right"): vec.x = 1
	return vec

func check_collisions():
	var overlapping = player_spawn_area.get_overlapping_bodies()
	var has_body = false
	for body in overlapping:
		if body == self:
			continue
		if body.is_in_group("Enemies") or body.is_in_group("Players"):
			has_body = true
			break
	if not has_body:
		check_blocked = true
		remove_from_group("PlayersDisabled")
		player_area.remove_from_group("PlayersDisabled")
		set_collision_layer_value(12, false)
		add_to_group("Players")
		player_area.add_to_group("Players")
		set_collision_layer_value(4, true)

		set_collision_mask_value(4, true)
		set_collision_mask_value(5, true)
	else:
		check_blocked = false

func handle_shooting():
	var shoot_press = Input.is_action_just_pressed("game" + str(player_id) + "_shoot")
	if Global.auto_fire:
		shoot_press = Input.is_action_pressed("game" + str(player_id) + "_shoot")
	if shoot_press:
		if weapon_component.try_shoot(global_position, cur_state, player_id, self):
			SoundManager.play_sound("bullet_fired")

func update_rotation_and_animation(input: Vector2):
	if input.y == -1: boat.rotation_degrees = 0.0
	elif input.y == 1: boat.rotation_degrees = 180.0
	elif input.x == -1: boat.rotation_degrees = -90.0
	elif input.x == 1: boat.rotation_degrees = 90.0
	var new_state: String
	if abs(input.x) > abs(input.y):
		new_state = "right" if input.x > 0 else "left"
	else:
		new_state = "down" if input.y > 0 else "up"
	if new_state != cur_state or not sprite.is_playing():
		cur_state = new_state
		sprite.play(cur_state + "_" + stars_to_anim())

func handle_move_sound():
	if not is_frozen:
		if is_on_water and on_boat:
			SoundManager.play_sound("player_water")
			SoundManager.stop_sound("player_moving")
		else:
			SoundManager.play_sound("player_moving")

func get_offset() -> Vector2:
	if cur_state == "up":
		return Vector2(0.0, -7.0)
	elif cur_state == "down":
		return Vector2(0.0, 7.0)
	elif cur_state == "left":
		return Vector2(-7.0, 0.0)
	elif cur_state == "right":
		return Vector2(7.0, 0.0)
	return Vector2.ZERO

func snap_to_tile_center():
	var best_pos = global_position
	best_pos = get_snapped_position(best_pos, 8)
	global_position = best_pos

func get_snapped_position(pos: Vector2, snap: int = 8) -> Vector2:
	return Vector2(
		round(pos.x / snap) * snap,
		round(pos.y / snap) * snap
	)

# collision
func check_floor_type():
	var map_coords = terrain_layer.local_to_map(global_position)
	var positions: Array = [
		map_coords - Vector2i(0, 1), map_coords - Vector2i(0, 2),
		map_coords - Vector2i(1, 1), map_coords - Vector2i(1, 2)
	]

	is_on_ice = false
	is_on_water = false

	for pos in positions:
		var tile_data = terrain_layer.get_cell_tile_data(pos)
		if tile_data:
			var type = tile_data.get_custom_data("Type")
			if type == "ice":
				is_on_ice = true
			if type == "water":
				is_on_water = true

func receive_hit(is_fatal: bool = false):
	if is_invencible and not is_fatal: return
	if not operating: return

	if on_boat and not is_fatal:
		toggle_boat(false)
		SoundManager.play_sound("down_star")
		apply_invencibility(1.0)

	elif Global.get_stars(player_id) > 2 and not is_fatal:
		level.player_hitted = true
		toggle_boat(false)
		toggle_cut_tree(false)
		Global.decrease_stars(player_id)
		SoundManager.play_sound("down_star")
		apply_invencibility(1.0)
		sprite.play(cur_state + "_" + stars_to_anim())

	else:
		operating = false
		level.player_hitted = true
		generate_explosion()
		SoundManager.play_sound("player_hitted")
		SoundManager.stop_sound("player_moving")
		flick_animation.stop()
		freeze_player_timer.stop()
		if not hitted_by_granade:
			if Global.get_lifes(player_id) > 0:
				Global.decrease_lifes(player_id)
				respawn_timer.start(0.5)
			else:
				level.player_game_over(player_id)
		else:
			respawn_timer.start(0.5)
		Global.decrease_stars(player_id)
		toggle_boat(false)
		toggle_cut_tree(false)
		is_freeze(false)
		collision.set_deferred("disabled", true)
		sprite.visible = false
		
		check_blocked = true
		remove_from_group("Players")
		player_area.remove_from_group("Players")
		set_collision_layer_value(12, true)
		add_to_group("PlayersDisabled")
		player_area.add_to_group("PlayersDisabled")
		set_collision_layer_value(4, false)
		set_collision_mask_value(4, false)
		set_collision_mask_value(5, false)

func generate_explosion():
	var explosion = EXPLOSION_SCENE.instantiate()
	add_sibling(explosion)
	explosion.position = global_position
	explosion.explosion_type("mini")

func apply_invencibility(time: float):
	invencible.visible = true
	invencible.play("invencible")
	is_invencible = true
	invencible_timer.start(time)

func add_star():
	if Global.hard_mode:
		if Global.get_stars(player_id) == 5: return
	else:
		if Global.get_stars(player_id) == 4: return
	sprite.play(cur_state + "_" + stars_to_anim())
	Global.add_stars(player_id)

func gain_life():
	Global.add_lifes(player_id)

func toggle_cut_tree(enable: bool):
	Global.toggle_cut_tree(player_id, enable)

func toggle_boat(enable: bool):
	on_boat = enable
	boat.visible = enable
	Global.toggle_boat(player_id, enable)
	set_collision_mask_value(3, not enable)

func is_freeze(enable: bool = true):
	if enable:
		is_frozen = true
		flick_animation.play("flick")
		freeze_player_timer.start(8.0)
	else:
		is_frozen = false
		if operating:
			flick_animation.play("visible")

func _on_freeze_players_timeout() -> void:
	is_freeze(false)

func stars_to_anim() -> String:
	var state = Global.get_stars(player_id)
	if state >= 5:
		return "4"
	return str(state)

func disable_actions():
	operating = false
	var friction = ice_friction if is_on_ice else normal_friction
	velocity = velocity.move_toward(Vector2.ZERO, friction)
	sprite.pause()
	SoundManager.stop_sound("player_moving")

func spawn_player():
	global_position = spawn_position
	hitted_by_granade = false
	spawn.visible = true
	sprite.play(cur_state + "_" + stars_to_anim())
	sprite.stop()
	toggle_boat(Global.get_boat_state(player_id))
	toggle_cut_tree(Global.get_cut_tree_state(player_id))
	if not sprite.material:
		sprite.material = Material.new()
		update_player_palette()
	spawn.play("spawn")

func _on_spawn_animation_finished() -> void:
	operating = true
	check_collisions()
	collision.disabled = false
	spawn.visible = false
	sprite.visible = true
	cur_state = "up"
	sprite.play(cur_state + "_" + stars_to_anim())
	apply_invencibility(3.0)

func _on_invencible_timeout() -> void:
	invencible.visible = false
	is_invencible = false

func _on_respawn_timeout() -> void:
	spawn_player()

func update_player_palette():
	if not sprite.material: return
	match player_id:
		1:
			sprite.material = preload("res://shaders_material/player_one_shader_material.tres")
		2:
			sprite.material = preload("res://shaders_material/player_two_shader_material.tres")
		3:
			sprite.material = preload("res://shaders_material/player_three_shader_material.tres")
		4:
			sprite.material = preload("res://shaders_material/player_four_shader_material.tres")
