extends Area2D

@onready var level: Node2D = $".."
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var animation: AnimationPlayer = $Animation

@export var bonus_id: int = 0
@export var area_x_min: float = 0.0
@export var area_x_max: float = 50.0
@export var area_y_min: float = 0.0
@export var area_y_max: float = 50.0

var POINTS_SCENE = preload("res://scenes/hud/points.tscn")
var points = 500
var player_who_collect: int = 0

var is_active: bool = false
var powerup_type: String = ""

func generate_powerup():
	is_active = true
	monitoring = true
	powerup_type = _get_powerup()
	_move_to_random()
	sprite.play(powerup_type)
	animation.play("flicking")
	SoundManager.play_sound("spawn_item")
	visible = true

func _get_powerup() -> String:
	var powerups: Array
	powerups = sprite.sprite_frames.get_animation_names()
	if powerups.size() > 0:
		return powerups.pick_random()
	return ""

func _move_to_random():
	var obstacles = []
	obstacles.append_array(get_tree().get_nodes_in_group("Players"))
	obstacles.append_array(get_tree().get_nodes_in_group("PlayersDisabled"))
	obstacles.append_array(get_tree().get_nodes_in_group("Enemies"))
	obstacles.append_array(get_tree().get_nodes_in_group("EnemiesDisabled"))
	obstacles.append_array(get_tree().get_nodes_in_group("Powerups"))
	var max_attempts = 20
	var min_distance = 16.0
	var candidate_pos = Vector2.ZERO
	
	for i in range(max_attempts):
		var rand_x = randf_range(area_x_min, area_x_max)
		var rand_y = randf_range(area_y_min, area_y_max)

		candidate_pos = get_snapped_position(Vector2(rand_x, rand_y))
		var is_valid = true

		for obstacle in obstacles:
			if obstacle == null or not is_instance_valid(obstacle):
				continue

			var distance = candidate_pos.distance_to(obstacle.global_position)
			if distance < min_distance:
				is_valid = false

		if is_valid:
			self.global_position = candidate_pos
			return

	self.global_position = candidate_pos

func get_snapped_position(pos: Vector2, snap: int = 8) -> Vector2:
	return Vector2(
		round(pos.x / snap) * snap,
		round(pos.y / snap) * snap
	)

func despawn_powerup(player: int):
	is_active = false
	animation.play("RESET")
	set_deferred("monitoring", false)
	visible = false

	if player != 0:
		var pt = POINTS_SCENE.instantiate()
		add_sibling(pt)
		pt.position = global_position
		pt.set_points(500)
		Global.add_score(player, 500)

func apply_effect(body: Node2D, is_bot: bool):
	match powerup_type:
		"helmet":
			body.apply_invencibility(12.0)
		"star":
			body.add_star()
		"ammo":
			if is_bot:
				level.upgrade_active_bots()
			else:
				if Global.get_cut_tree_state(body.player_id):
					body.add_star()
				else:
					body.toggle_cut_tree(true)
		"life":
			if is_bot:
				level.protect_active_bots()
			else:
				body.gain_life()
		"clock":
			level.freeze_bots(true, is_bot)
		"granade":
			level.kill_active_bots(is_bot)
		"shovel":
			level.protect_eagle(is_bot)
		"boat":
			body.toggle_boat(true)

	if is_bot:
		SoundManager.play_sound("item_enemy")
	else:
		if powerup_type != "life":
			SoundManager.play_sound("item_collected")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("PlayersDisabled"):
		apply_effect(body, false)
		despawn_powerup(body.player_id)
	
	elif body.is_in_group("Players"):
		apply_effect(body, false)
		despawn_powerup(body.player_id)

	elif body.is_in_group("EnemiesDisabled"):
		if Global.bot_use_bonus:
			apply_effect(body, true)
			despawn_powerup(0)
	
	elif body.is_in_group("Enemies"):
		if Global.bot_use_bonus:
			apply_effect(body, true)
			despawn_powerup(0)
