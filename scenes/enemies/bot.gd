extends CharacterBody2D

signal bot_hit
signal bot_died

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var invencible: AnimatedSprite2D = $Invencible
@onready var spawn: AnimatedSprite2D = $Spawn
@onready var boat: Sprite2D = $Boat

@onready var collision: CollisionShape2D = $Collision
@onready var bot_spawn_area: Area2D = $BotSpawnArea
@onready var bot_area: Area2D = $BotArea

@onready var invencible_timer: Timer = $InvencibleTimer
@onready var shot_timer: Timer = $ShotTimer
@onready var turn_timer: Timer = $TurnTimer
@onready var pallete_timer: Timer = $PalleteTimer

var base_node: Node2D = null

var bots_group_node: Node2D = null

const TILE_SIZE: float = 8.0

var operating: bool = false
var is_stopped: bool = false
var is_invencible: bool = true
var time_finished: bool = false
var is_frozen: bool = false
var collision_disabled: bool = false
var check_blocked: bool = true
var start_random_turn: bool = false
var updated_speed: bool = false

var bot_state: int = 1
var is_special: bool = false
var is_reinforcement: bool = false
var hitted_by_granade: bool = false
var player_who_hit: int = 0

var speed: float = 40.0
var cur_state: String = "down"
var shield: int = 0
var points: int = 100

var power: int  = 1
var fire_rate: Vector2 = Vector2(0.75, 1.5)

var tank_direction: String = "down"
var last_axis: String = "vertical"
var inline_top_time: float = 3.0
var inline_timer: float = 0.0
var on_boat: bool = false

var active_bullets: Array[Node2D] = []
var max_bullets: int = 2

var is_blinking: bool = false
var material_a: Material = null
var material_b: Material = null

var BULLET_SCENE = preload("res://scenes/bullets/bullet.tscn")
var EXPLOSION_SCENE = preload("res://scenes/bullets/explosion.tscn")
var SPECIAL_PALLETE: Material = preload("res://shaders_material/special_bot_shader_material.tres")
var SHIELD_EXTRA_WHITE_PALLETE: Material = preload("res://shaders_material/extra_shield_white_bot_shader_material.tres")
var SHIELD_EXTRA_PALLETE: Material = preload("res://shaders_material/extra_shield_bot_shader_material.tres")
var SHIELD_MAX_DARK_PALLETE: Material = preload("res://shaders_material/max_shield_dark_bot_shader_material.tres")
var SHIELD_MAX_PALLETE: Material = preload("res://shaders_material/max_shield_bot_shader_material.tres")
var SHIELD_HALF_PALLETE: Material = preload("res://shaders_material/half_shield_bot_shader_material.tres")
var SHIELD_LOW_PALLETE: Material = preload("res://shaders_material/low_shield_bot_shader_material.tres")

func _ready() -> void:
	bots_group_node = get_parent()
	base_node = get_tree().get_first_node_in_group("Base")

func generate_bot(state: int = 1, special: bool = false, reinforcement: bool = false):
	self.bot_state = state
	self.is_special = special
	self.is_reinforcement = reinforcement
	define_bot_type()
	add_extra_armor()
	verify_shader_material()
	spawn_bot()
	update_animation(Vector2.ZERO)

func define_bot_type():
	match bot_state:
		1:
			pass
		2:
			points = 200
			inline_top_time = 1.5
			speed = 80.0
			power = 2
			fire_rate = Vector2(0.5, 1.2)
		3:
			points = 300
			inline_top_time = 2.5
			power = 2
			speed = 50.0
			fire_rate = Vector2(0.6, 1.0)
		4:
			points = 400
			inline_top_time = 3.5
			power = 2
			speed = 30.0
			shield = 3
			fire_rate = Vector2(0.8, 1.2)

	if Global.hard_mode:
		speed += 10.0

func add_extra_armor():
	if is_reinforcement:
		if is_special:
			shield = 5
		else:
			shield = 4

	elif Global.current_gameplay_mode in [Global.GamePlay.CAMPAIGN, Global.GamePlay.FREEPLAY] and Global.hard_mode:
		if bot_state == 4:
			shield = randi_range(3, 4)
		else:
			shield = randi_range(0, 3)

	elif Global.current_gameplay_mode == Global.GamePlay.SURVIVAL:
		if Global.current_level_round >= 10:
			if bot_state != 4:
				var data: Dictionary = Global.level_round_data
				shield = randi_range(0, data.get("shield", 0))
		elif Global.current_level_round >= 20:
			if bot_state != 4:
				shield = randi_range(3, 4)
			else:
				var data: Dictionary = Global.level_round_data
				shield = randi_range(0, data.get("shield", 0))

func verify_shader_material():
	if (is_special or shield > 0) and not sprite.material:
		sprite.material = Material.new()
	update_bot_palette()

func start_ai_actions():
	shot_timer.start(randf_range(fire_rate.x, fire_rate.y))

func _physics_process(delta: float):
	if not operating or is_frozen:
		if sprite.is_playing():
			sprite.stop()
		return

	var input_vector = Vector2.ZERO
	match tank_direction:
		"up":
			input_vector.y = -1
			boat.rotation_degrees = 0.0
		"down":
			input_vector.y = 1
			boat.rotation_degrees = 180.0
		"left":
			input_vector.x = -1
			boat.rotation_degrees = -90.0
		"right":
			input_vector.x = 1
			boat.rotation_degrees = 90.0

	velocity = input_vector * speed
	update_animation(input_vector)
	SoundManager.play_sound("enemy_moving")

	var current_axis = get_axis(input_vector)
	if current_axis != last_axis:
		snap_to_tile_center()
		last_axis = current_axis

	if not is_stopped:
		inline_timer = max(inline_timer - delta, 0.0)
		if inline_timer <= 0 and not time_finished and start_random_turn:
			time_finished = true
			var rand_bool: bool = bool(randi() & 1)
			if rand_bool:
				turn_timer.start(0.1)
			else:
				time_finished = false
				inline_timer = randf_range(inline_top_time - 1.0, inline_top_time + 1.0)

	var collisor = move_and_collide(velocity * delta)
	if collisor and not is_stopped:
		start_random_turn = true
		is_stopped = true
		time_finished = false
		turn_timer.start(randf_range(0.3, 1.0))

func _process(_delta: float) -> void:
	if not check_blocked:
		check_collisions()

func tank_shoot():
	if not operating or is_frozen: return

	active_bullets = active_bullets.filter(
		func(b): return is_instance_valid(b)
	)
	if active_bullets.size() >= max_bullets:
		return

	var bullet = BULLET_SCENE.instantiate()
	active_bullets.append(bullet)
	add_sibling(bullet)
	bullet.position = global_position + get_offset()
	bullet.bullet_data("bot", cur_state, power)

func get_direction_to_base() -> String:
	if base_node == null:
		return "down"
	var dir = (base_node.global_position - global_position)
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func tank_turn():
	var preferred_dir = get_direction_to_base()
	var choices = {
		"up": 0.4,
		"down": 0.4,
		"left": 0.4,
		"right": 0.4
	}
	choices[preferred_dir] += 0.2

	#match tank_direction:
		#"up":
			#choices = {"left": 0.5, "right": 0.5, "down": 0.4}
		#"down":
			#choices = {"left": 0.5, "right": 0.5, "up": 0.4}
		#"left":
			#choices = {"up": 0.4, "down": 0.5, "right": 0.4}
		#"right":
			#choices = {"up": 0.4, "down": 0.5, "left": 0.4}

	var free_dirs: Array = get_free_directions()
	var brick_dirs: Array = get_brick_directions()
	var possible_dirs: Array = []
	
	for check in [free_dirs, brick_dirs]:
		for dir in check:
			if not possible_dirs.has(dir):
				possible_dirs.append(dir)

	var filtered_choices = {}
	for dir in choices.keys():
		if possible_dirs.has(dir):
			filtered_choices[dir] = choices[dir]

	if filtered_choices.is_empty():
		filtered_choices = {"left": 0.25, "right": 0.25, "down": 0.25, "up": 0.25}

	tank_direction = weighted_pick(filtered_choices)
	is_stopped = false
	inline_timer = inline_top_time

func weighted_pick(options: Dictionary) -> String:
	var total = 0.0
	for weight in options.values():
		total += weight
	var r = randf() * total
	for key in options.keys():
		r -= options[key]
		if r <= 0:
			return key
	return options.keys()[0]

func get_free_directions() -> Array[String]:
	var free_dirs: Array[String] = []
	var check_distance = TILE_SIZE
	var dir_vectors = {
		"up": Vector2(0, -1),
		"down": Vector2(0, 1),
		"left": Vector2(-1, 0),
		"right": Vector2(1, 0)
	}
	for dir in dir_vectors.keys():
		var offset = dir_vectors[dir] * check_distance
		if not test_move(transform, offset):
			free_dirs.append(dir)
	return free_dirs

func get_brick_directions() -> Array[String]:
	var brick_dirs: Array[String] = []
	if bots_group_node == null:
		return brick_dirs
	var tilemap: TileMapLayer = bots_group_node.get_parent().get_node_or_null("Terrain")
	if tilemap == null:
		return brick_dirs
	var dir_vectors: Dictionary = {
		"up": Vector2(0, -1),
		"down": Vector2(0, 1),
		"left": Vector2(-1, 0),
		"right": Vector2(1, 0)
	}
	var check1 = check_chunks(dir_vectors, Vector2(0.0, 0.0), tilemap)
	var check2 = check_chunks(dir_vectors, Vector2(-8.0, 0.0), tilemap)
	var check3 = check_chunks(dir_vectors, Vector2(0.0, -8.0), tilemap)
	var check4 = check_chunks(dir_vectors, Vector2(-8.0, -8.0), tilemap)
	for check in [check1, check2, check3, check4]:
		for dir in check:
			if not brick_dirs.has(dir):
				brick_dirs.append(dir)
	return brick_dirs

func check_chunks(arr: Dictionary, coord: Vector2, tilemap: TileMapLayer) -> Array:
	var new_arr: Array[String] = []
	for dir in arr.keys():
		var offset = arr[dir] * TILE_SIZE
		var check_pos = (global_position + coord) + offset
		var map_coords = tilemap.local_to_map(check_pos)
		var tile_data = tilemap.get_cell_tile_data(map_coords)
		if tile_data:
			var type = tile_data.get_custom_data("Type")
			if type.begins_with("brick"):
				new_arr.append(dir)
	return new_arr

func get_offset() -> Vector2:
	if cur_state == "up":
		return Vector2(0.0, -4.0)
	elif cur_state == "down":
		return Vector2(0.0, 4.0)
	elif cur_state == "left":
		return Vector2(-4.0, 0.0)
	elif cur_state == "right":
		return Vector2(4.0, 0.0)
	return Vector2.ZERO

func get_axis(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y):
		return "horizontal"
	elif abs(vec.y) > abs(vec.x):
		return "vertical"
	return last_axis

func snap_to_tile_center():
	var best_pos = global_position
	best_pos = get_snapped_position(best_pos, 8)
	global_position = best_pos

func get_snapped_position(pos: Vector2, snap: int = 8) -> Vector2:
	return Vector2(
		round(pos.x / snap) * snap,
		round(pos.y / snap) * snap
	)

func update_animation(input_vector: Vector2):
	var new_state: String

	if abs(input_vector.x) > abs(input_vector.y):
		new_state = "right" if input_vector.x > 0 else "left"
	else:
		new_state = "down" if input_vector.y > 0 else "up"

	if new_state != cur_state or not sprite.is_playing():
		cur_state = new_state
		sprite.play(cur_state + "_" + str(bot_state))

func receive_hit(player: int):
	if is_invencible and player != -1: return
	
	player_who_hit = player
	
	bot_hit.emit()
	if on_boat and player_who_hit != -1:
		toggle_boat(false)
		SoundManager.play_sound("hit_shield")

	elif shield > 0 and player_who_hit != -1:
		shield -= 1
		if Global.hard_mode:
			Global.add_score(player_who_hit, 1)
		SoundManager.play_sound("hit_shield")
		verify_shader_material()
	else:
		kill_bot()

func kill_bot():
	operating = false
	generate_explosion(player_who_hit)
	Global.add_score(player_who_hit, points)
	if player_who_hit != -1:
		SoundManager.play_sound("enemy_hitted")
	SoundManager.stop_sound("enemy_moving")
	bot_died.emit()
	queue_free()

func generate_explosion(player: int):
	var bot_points = points
	if player == -1: bot_points = 0

	var explosion = EXPLOSION_SCENE.instantiate()
	add_sibling(explosion)
	explosion.position = global_position
	explosion.explosion_type("big", bot_points)

func disable_special_mode():
	is_special = false
	verify_shader_material()

func apply_invencibility(time: float):
	invencible.visible = true
	invencible.play("invencible")
	is_invencible = true
	invencible_timer.start(time)

func add_star():
	power = 4
	shield += 2
	verify_shader_material()

func upgrade_armor():
	if updated_speed: return
	updated_speed = true
	speed += 10.0
	shield += 1
	verify_shader_material()

func gain_life():
	shield += 3
	verify_shader_material()

func toggle_boat(enable: bool):
	on_boat = enable
	boat.visible = enable
	set_collision_mask_value(3, not enable)

func spawn_bot():
	spawn.visible = true
	collision_disabled = true
	spawn.play("spawn")

func _on_spawn_animation_finished() -> void:
	operating = true
	check_collisions()
	spawn.visible = false
	sprite.visible = true
	tank_direction = get_spawn_direction_to_base()
	cur_state = tank_direction
	sprite.play(cur_state + "_" + str(bot_state))
	collision.disabled = false
	start_ai_actions()
	apply_invencibility(1.0)

func get_spawn_direction_to_base() -> String:
	if base_node == null:
		return "down"
	var dir = base_node.global_position - global_position
	if abs(dir.x) > abs(dir.y):
		return "right" if dir.x > 0 else "left"
	else:
		return "down" if dir.y > 0 else "up"

func _on_invencible_timeout() -> void:
	invencible.visible = false
	is_invencible = false

func _on_shot_timeout() -> void:
	tank_shoot()

func _on_turn_timeout() -> void:
	tank_turn()

func check_collisions():
	var overlapping = bot_spawn_area.get_overlapping_bodies()
	var has_body = false
	for body in overlapping:
		if body == self:
			continue
		if body.is_in_group("Enemies") or body.is_in_group("Players"):
			has_body = true
			break
	if not has_body:
		check_blocked = true
		remove_from_group("EnemiesDisabled")
		bot_area.remove_from_group("EnemiesDisabled")
		set_collision_layer_value(11, false)
		add_to_group("Enemies")
		bot_area.add_to_group("Enemies")
		set_collision_layer_value(5, true)

		set_collision_mask_value(4, true)
		set_collision_mask_value(5, true)
	else:
		check_blocked = false

func start_blinking(mat_a: Material, mat_b: Material, interval: float):
	stop_blinking()
	is_blinking = true
	material_a = mat_a
	material_b = mat_b
	sprite.material = material_a
	pallete_timer.wait_time = interval
	pallete_timer.start()

func stop_blinking(final_material: Material = null):
	if not is_blinking and sprite.material == final_material:
		return
	pallete_timer.stop()
	is_blinking = false
	material_a = null
	material_b = null
	sprite.material = final_material

func _on_pallete_timeout() -> void:
	if not is_blinking:
		return
	if sprite.material == material_a:
		sprite.material = material_b
	else:
		sprite.material = material_a

func update_bot_palette():
	if not sprite.material:
		return

	if is_special:
		start_blinking(SPECIAL_PALLETE, null, 0.2)
	elif shield > 3:
		start_blinking(SHIELD_EXTRA_PALLETE, SHIELD_EXTRA_WHITE_PALLETE, 0.06)
	elif shield > 2:
		start_blinking(SHIELD_MAX_PALLETE, SHIELD_MAX_DARK_PALLETE, 0.08)
	elif shield > 1:
		start_blinking(SHIELD_HALF_PALLETE, SHIELD_MAX_PALLETE, 0.03)
	elif shield > 0:
		start_blinking(SHIELD_LOW_PALLETE, SHIELD_HALF_PALLETE, 0.02)
	else:
		stop_blinking(null)
