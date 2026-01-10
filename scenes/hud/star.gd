extends AnimatedSprite2D

func define_rank(num: int):
	if num >= 5: num = 4
	play("level_" + str(num))

func define_super_rank(num: int):
	if num >= 5: num = 4
	play("super_level_" + str(num))
