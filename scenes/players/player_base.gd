extends StaticBody2D

@onready var level: Node2D = $".."
@onready var collision: CollisionShape2D = $Collision
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var EXPLOSION_SCENE = preload("res://scenes/bullets/explosion.tscn")

var is_invencible: bool = false

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
