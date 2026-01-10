extends LineEdit

var regex := RegEx.new()

func _ready():
	regex.compile("[a-zA-Z0-9_]")
	connect("text_changed", Callable(self, "_on_text_changed"))

func _on_text_changed(new_text):
	var cleaned_text := ""
	for character in new_text:
		if regex.search(character):
			cleaned_text += character

	if cleaned_text != new_text:
		var cursor_pos = caret_column
		text = cleaned_text
		caret_column = min(cursor_pos, text.length())   
