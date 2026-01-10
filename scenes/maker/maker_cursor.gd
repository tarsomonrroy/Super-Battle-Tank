extends AnimatedSprite2D

func change_sprite(index: int = -1):
	play(get_tile_anim(index))

func get_tile_anim(index: int) -> String:
	match index:
		0:
			return "brick"
		1:
			return "brick_1"
		2:
			return "brick_2"
		3:
			return "brick_3"
		4:
			return "brick_4"
		5:
			return "metal"
		6:
			return "ice"
		7:
			return "water"
		8:
			return "tree"
		9:
			return "flower"
	return "block"
