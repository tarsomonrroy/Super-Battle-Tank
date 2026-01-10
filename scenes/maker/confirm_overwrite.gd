extends PanelContainer

signal overwrite_confirmed
signal overwrite_cancelled

@onready var title: Label = $VBoxContainer/Title

func show_overwrite(levelname: String):
	levelname = levelname.to_upper()
	levelname = levelname.replace("_", " ")
	if levelname.length() > 20:
		levelname = levelname.substr(0, 20)
	
	var msg = Global.get_translated_text("OVERWRITE")
	title.text = msg + " \"" + levelname + "\"?"
	show()

func _on_yes_option_pressed() -> void:
	overwrite_confirmed.emit()

func _on_no_option_pressed() -> void:
	overwrite_cancelled.emit()
