extends Node

var language: String = "english"
var all_languages: Array = [
	"english", "espanol", "portugues",
	"francais", "deutsch", "italiano",
	"nederlands", "magyar", "turk",
	"русский", "ελληνικά", "bahasaindonesia"
]
var original_languages: Array = [
	"english", "español", "português",
	"français", "deutsch", "italiano",
	"nederlands", "magyar", "türk",
	"русский", "ελληνικά", "bahasa indonesia"
]
var language_acronym: Array = [
	"en", "es", "pt",
	"fr", "de", "it",
	"nl", "hu", "tr",
	"ru", "el", "id"
]

func set_game_language(lang: String):
	TranslationServer.set_locale(lang)

func get_next_language():
	var index = all_languages.find(language)
	if index == all_languages.size() - 1:
		index = 0
	else:
		index += 1
	language = all_languages[index]
	set_game_language(language)

func get_original_language() -> String:
	var index = all_languages.find(language)
	return original_languages[index].to_upper()

func get_translated_text(text: String) -> String:
	var msg = TranslationServer.get_translation_object(language).get_message(text)
	return msg

## Return "en", "es" or "pt"
func get_language_acronym() -> String:
	var index = all_languages.find(language)
	return language_acronym[index]
