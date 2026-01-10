class_name WeaponComponent extends Node

@export var bullet_scene: PackedScene

var active_bullets: Array[Node2D] = []
var shot_cooldown: float = 0.0
var default_cooldown: float = 0.1

func process_cooldown(delta: float):
	shot_cooldown = max(shot_cooldown - delta, 0.0)

func try_shoot(origin: Vector2, direction: String, player_id: int, parent_node: Node) -> bool:
	active_bullets = active_bullets.filter(func(b): return is_instance_valid(b))

	var max_bullets = 1
	var stars = Global.get_stars(player_id)
	
	if Global.hard_mode and stars == 5: max_bullets = 3
	elif stars >= 3: max_bullets = 2

	if active_bullets.size() >= max_bullets: return false
	if shot_cooldown > 0.0: return false

	var bullet = bullet_scene.instantiate()
	active_bullets.append(bullet)
	parent_node.add_sibling(bullet)
	
	bullet.position = origin + get_offset(direction)
	bullet.bullet_data("player", direction, stars, player_id, Global.get_cut_tree_state(player_id))
	
	shot_cooldown = default_cooldown
	return true

func get_offset(cur_state: String) -> Vector2:
	match cur_state:
		"up": return Vector2(0.0, -7.0)
		"down": return Vector2(0.0, 7.0)
		"left": return Vector2(-7.0, 0.0)
		"right": return Vector2(7.0, 0.0)
	return Vector2.ZERO
