extends PanelContainer

signal overwrite_confirmed
signal overwrite_cancelled

@onready var title: Label = $VBoxContainer/Title

func _process(_delta: float) -> void:
	if visible:
		if Input.is_action_just_pressed("menu_accept") or Input.is_action_just_pressed("game1_pause"):
			_on_yes_option_pressed()
		elif Input.is_action_just_pressed("menu_back") or Input.is_action_just_pressed("game1_exit"):
			_on_no_option_pressed()

func show_overwrite(levelname: String):
	levelname = levelname.to_upper()
	levelname = levelname.replace("_", " ")
	if levelname.length() > 20:
		levelname = levelname.substr(0, 20)
	
	var msg = GameTranslation.get_translated_text("OVERWRITE")
	title.text = msg + " \"" + levelname + "\"?"
	show()

func _on_yes_option_pressed() -> void:
	overwrite_confirmed.emit()

func _on_no_option_pressed() -> void:
	overwrite_cancelled.emit()
