extends AnimatedSprite2D

func set_points(points: int = 100):
	if points not in [100, 200, 300, 400, 500]:
		queue_free()
		return

	play(str(points))
	await get_tree().create_timer(0.5).timeout
	queue_free()
