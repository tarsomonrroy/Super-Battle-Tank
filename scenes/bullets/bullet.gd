extends Area2D

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var area_left_up: Area2D = $AreaLeftUp
@onready var area_left_down: Area2D = $AreaLeftDown
@onready var area_right_up: Area2D = $AreaRightUp
@onready var area_right_down: Area2D = $AreaRightDown
@onready var bullet_trail: CPUParticles2D = $BulletTrail

var speed_velocity: float = 120.0
var bullet_power: int = 1
var shooter: String = ""
var cut_tree: bool = false
var direction: String = "up"
var offset: Vector2i = Vector2i(1, 0)
var player_who_shot: int = 0

var trail_position: Dictionary = {
	"up": Vector2(-0.5, 1.0),
	"down": Vector2(0.5, -1.0),
	"left": Vector2(1.0, 0.5),
	"right": Vector2(-1.0, -0.5)
}

var EXPLOSION_SCENE = preload("res://scenes/bullets/explosion.tscn")

func bullet_data(entity: String, direct: String, power: int, player: int = 0, tree: bool = false):
	self.shooter = entity
	self.direction = direct
	self.bullet_power = power
	self.player_who_shot = player
	self.cut_tree = tree

	bullet_trail.color_ramp = load("res://scenes/bullets/bullet_colo_ramp.tres")
	if cut_tree:
		sprite.modulate = Color("ff7a7a")
		bullet_trail.color_ramp.set_color(0, Color("ff000032"))
	bullet_trail.emitting = true

	change_speed()
	change_collision()

	monitoring = true

func _physics_process(delta: float) -> void:
	match direction:
		"up":
			position += Vector2.UP * delta * speed_velocity
		"down":
			position += Vector2.DOWN * delta * speed_velocity
		"left":
			position += Vector2.LEFT * delta * speed_velocity
		"right":
			position += Vector2.RIGHT * delta * speed_velocity
	sprite.play(direction)
	bullet_trail.position = trail_position[direction]
	if cut_tree:
		check_grass_tiles()

func check_grass_tiles() -> void:
	var areas = [area_left_up, area_left_down, area_right_up, area_right_down]
	var terrain_layers = get_tree().get_nodes_in_group("Terrain")
	
	for area in areas:
		for terrain in terrain_layers:
			var map_coords = terrain.local_to_map(terrain.to_local(area.global_position))
			var tile_data = terrain.get_cell_tile_data(map_coords)
			if tile_data and tile_data.get_custom_data("Type") == "grass":
				terrain.set_cell(map_coords, -1)
				if shooter == "player":
					Global.add_score(player_who_shot, 25)
					SoundManager.play_sound("cut_tree")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Terrain"):
		generate_explosion()
		terrain_hitted(body)

	elif body.is_in_group("Base"):
		body.base_destroyed()
		generate_explosion()
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Bullet"):
		if area.shooter != self.shooter:
			queue_free()

	elif area.is_in_group("Players") and shooter != "player":
		var body = area.get_parent()
		if body.operating:
			body.receive_hit()
			generate_explosion(body)
			queue_free()

	elif area.is_in_group("PlayersDisabled") and shooter != "player":
		var body = area.get_parent()
		if body.operating:
			body.receive_hit()
			generate_explosion(body)
			queue_free()

	elif area.is_in_group("Enemies") and shooter == "player":
		var body = area.get_parent()
		if body.operating:
			body.receive_hit(player_who_shot)
			generate_explosion(body)
			queue_free()

	elif area.is_in_group("EnemiesDisabled") and shooter == "player":
		var body = area.get_parent()
		if body.operating:
			body.receive_hit(player_who_shot)
			generate_explosion(body)
			queue_free()

func terrain_hitted(terrain: TileMapLayer):
	var hit_left: Vector2 = Vector2.ZERO
	var hit_right: Vector2 = Vector2.ZERO

	match direction:
		"up":
			hit_left = area_left_up.global_position
			hit_right = area_right_up.global_position
		"down":
			hit_left = area_left_down.global_position
			hit_right = area_right_down.global_position
		"left":
			hit_left = area_left_up.global_position
			hit_right = area_left_down.global_position
		"right":
			hit_left = area_right_up.global_position
			hit_right = area_right_down.global_position

	tile_action(terrain, hit_left)
	tile_action(terrain, hit_right)
	queue_free()

func tile_action(collisor: TileMapLayer, pos: Vector2):
	var map_coords = collisor.local_to_map(collisor.to_local(pos))
	var tile_data = collisor.get_cell_tile_data(map_coords)
	if not tile_data: return

	var source_id = collisor.get_cell_source_id(map_coords)
	var type = tile_data.get_custom_data("Type")

	if bullet_power >= 4 or cut_tree:
		if type.begins_with("brick"):
			collisor.set_cell(map_coords, -1)
			if shooter == "player":
				Global.add_score(player_who_shot, 10)
				SoundManager.play_sound("brick_broken")

		elif type == "metal":
			collisor.set_cell(map_coords, -1)
			if shooter == "player":
				Global.add_score(player_who_shot, 50)
				SoundManager.play_sound("brick_broken")

		elif type == "wall":
			if shooter == "player":
				SoundManager.play_sound("wall_hitted")
		return

	match type:
		"brick_full":
			var new_tile_coords: Vector2i
			match direction:
				"up":
					new_tile_coords = Vector2i(4, 0)
				"down":
					new_tile_coords = Vector2i(2, 0)
				"left":
					new_tile_coords = Vector2i(3, 0)
				"right":
					new_tile_coords = Vector2i(1, 0)
			collisor.set_cell(map_coords, source_id, new_tile_coords)
			if shooter == "player":
				Global.add_score(player_who_shot, 5)
				SoundManager.play_sound("brick_broken")

		"brick_top", "brick_bottom", "brick_left", "brick_right":
			collisor.set_cell(map_coords, -1)
			if shooter == "player":
				Global.add_score(player_who_shot, 5)
				SoundManager.play_sound("brick_broken")

		"metal":
			if shooter == "player":
				SoundManager.play_sound("wall_hitted")

		"wall":
			if shooter == "player":
				SoundManager.play_sound("wall_hitted")

func generate_explosion(body: Node2D = null):
	if body != null and body.is_invencible: return

	var explosion = EXPLOSION_SCENE.instantiate()
	add_sibling(explosion)
	explosion.position = global_position
	explosion.explosion_type("mini")

func change_speed():
	match bullet_power:
		1:
			speed_velocity = 135.0
		2, 3:
			speed_velocity = 200.0
			if cut_tree:
				speed_velocity += 10.0
		4:
			speed_velocity = 200.0
			if cut_tree:
				speed_velocity += 25.0
		5:
			speed_velocity = 235.0
			if cut_tree:
				speed_velocity += 15.0

func change_collision():
	match shooter:
		"bot":
			set_collision_mask_value(5, false)
		"player":
			set_collision_mask_value(4, false)
