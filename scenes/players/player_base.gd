extends StaticBody2D

@onready var level: Node2D = $".."
@onready var collision: CollisionShape2D = $Collision
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var EXPLOSION_SCENE = preload("res://scenes/bullets/explosion.tscn")

var is_invencible: bool = false

var base_position: Dictionary = {
	"down": Vector2(224.0, 224.0),
	"up": Vector2(224.0, 32.0),
	"left": Vector2(128.0, 128.0),
	"right": Vector2(320.0, 128.0)
}
var base_exclusion_rects: Dictionary = {
	"down": Rect2i(19, 25, 4, 3),
	"up": Rect2i(19, 2, 4, 3),
	"left": Rect2i(8, 13, 3, 4),
	"right": Rect2i(31, 13, 3, 4)
}
var protection_area: Dictionary = {
	"down": [
		Vector2i(19,27), Vector2i(19,26), Vector2i(19,25), Vector2i(20,25),
		Vector2i(21,25), Vector2i(22,25), Vector2i(22,26), Vector2i(22,27),
	],
	"up": [
		Vector2i(19,2), Vector2i(19,3), Vector2i(19,4), Vector2i(20,4),
		Vector2i(21,4), Vector2i(22,4), Vector2i(22,3), Vector2i(22,2),
	],
	"left": [
		Vector2i(8,13), Vector2i(9,13), Vector2i(10,13), Vector2i(10,14),
		Vector2i(8,16), Vector2i(9,16), Vector2i(10,16), Vector2i(10,15),
	],
	"right": [
		Vector2i(31,13), Vector2i(32,13), Vector2i(33,13), Vector2i(31,14),
		Vector2i(31,16), Vector2i(32,16), Vector2i(33,16), Vector2i(31,15),
	],
}

func active_base(pos: Vector2, side: String = "down"):
	collision.disabled = false
	visible = true
	position = pos
	rotation_degrees = get_base_rotation(side)

func get_base_rotation(side: String) -> float:
	match side:
		"down":
			return 0.0
		"up":
			return 180.0
		"left":
			return 90.0
		"right":
			return -90.0
	return 0.0

func base_destroyed():
	if is_invencible: return
	SoundManager.play_sound("player_hitted")
	generate_explosion()
	collision.set_deferred("disabled", true)
	sprite.play("destroyed")
	level.base_destroyed()

func generate_explosion():
	var explosion = EXPLOSION_SCENE.instantiate()
	add_sibling(explosion)
	explosion.position = global_position
	explosion.explosion_type("big")
