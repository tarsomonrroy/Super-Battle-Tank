extends Camera2D

var shake_duration: float = 0.0
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready():
	offset = Vector2.ZERO

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta

		if shake_timer <= 0:
			shake_timer = 0.0
			offset = Vector2.ZERO
		else:
			var decay = pow(shake_timer / shake_duration, 2)
			var current_intensity = shake_intensity * decay
			var shake_x = randf_range(-current_intensity, current_intensity)
			var shake_y = randf_range(-current_intensity, current_intensity)
			offset = Vector2(shake_x, shake_y)

## Inicia o efeito de tremor com a intensidade e duração dadas.
func start_shake(intensity: float, duration: float):
	shake_intensity = intensity
	shake_duration = duration
	shake_timer = duration
