class_name MovementComponent extends Node

@export var actor: CharacterBody2D
@export var normal_friction: float = 2000.0
@export var ice_friction: float = 100.0

var speed: float = 30.0
var last_axis: String = "vertical"
var is_on_ice: bool = false
var moved: bool = false

func handle_movement(input_vector: Vector2, delta: float, bonus_speed: float) -> void:
	if input_vector != Vector2.ZERO:
		moved = true
		input_vector = input_vector.normalized()

		actor.velocity = input_vector * (speed + bonus_speed)

		var current_axis = get_axis(input_vector)
		if current_axis != last_axis:
			snap_to_tile_center()
			last_axis = current_axis
	else:
		var friction = ice_friction if is_on_ice else normal_friction
		actor.velocity = actor.velocity.move_toward(Vector2.ZERO, friction * delta)
		if moved and actor.velocity == Vector2.ZERO:
			moved = false

	actor.move_and_slide()

func stop_immediately():
	actor.velocity = Vector2.ZERO
	moved = false

func get_axis(vec: Vector2) -> String:
	if abs(vec.x) > abs(vec.y): return "horizontal"
	elif abs(vec.y) > abs(vec.x): return "vertical"
	return last_axis

func snap_to_tile_center():
	var best_pos = actor.global_position
	actor.global_position = Vector2(
		round(best_pos.x / 8.0) * 8.0,
		round(best_pos.y / 8.0) * 8.0
	)
