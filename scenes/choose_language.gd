extends Node2D

signal language_selected(lang: String)

@export var inactive_alpha := 0.3
@export var active_alpha := 1.0

var options: Array[Label]
var current_index := 0
var can_input := false

@onready var anim: AnimationPlayer = $"../AnimationPlayer"

func _ready():
	options = [
		$english,
		$espanol,
		$portugues
	]
	update_focus()

func open():
	visible = true
	current_index = 0
	update_focus()
	can_input = false
	anim.play("language_in")
	await anim.animation_finished
	can_input = true

func _process(_delta):
	if not can_input:
		return

	if Input.is_action_just_pressed("menu_down"):
		current_index = (current_index + 1) % options.size()
		update_focus()

	elif Input.is_action_just_pressed("menu_up"):
		current_index = (current_index - 1 + options.size()) % options.size()
		update_focus()

	elif Input.is_action_just_pressed("menu_accept"):
		select_language()

func update_focus():
	for i in options.size():
		options[i].modulate.a = active_alpha if i == current_index else inactive_alpha

func select_language():
	can_input = false
	var lang_name := options[current_index].name
	emit_signal("language_selected", lang_name)
	anim.play("language_out")
