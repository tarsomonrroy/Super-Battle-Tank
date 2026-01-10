extends AnimatedSprite2D

var POINTS_SCENE = preload("res://scenes/hud/points.tscn")
var points: int = 0

func explosion_type(type: String, score: int = 0):
	points = score
	if type == "big":
		play("big")
	else:
		play("mini")

func _on_animation_finished() -> void:
	if points != 0:
		var pt = POINTS_SCENE.instantiate()
		add_sibling(pt)
		pt.position = global_position
		pt.set_points(points)
	queue_free()
