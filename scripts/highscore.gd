extends Node

const HIGHSCORE_FILE = "user://highscores.save"

var highscores: Array = [ 0, 0, 0, 0 ]
var hard_highscores: Array = [ 0, 0, 0, 0 ]
var levels_unlocked: int = 1

var level_scores: Dictionary = {}

func _ready() -> void:
	load_highscores()

func save_highscores():
	var data = {
		"highscore": highscores,
		"hard_highscores": hard_highscores,
		"levels_unlocked": levels_unlocked,
		"level_scores": level_scores
	}
	var file = FileAccess.open_encrypted_with_pass(HIGHSCORE_FILE, FileAccess.WRITE, "battle_tank_highscore")
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_highscores():
	if FileAccess.file_exists(HIGHSCORE_FILE):
		var file = FileAccess.open_encrypted_with_pass(HIGHSCORE_FILE, FileAccess.READ, "battle_tank_highscore")
		if file:
			var content = file.get_as_text()
			file.close()
			var data = JSON.parse_string(content)
			highscores = data.get("highscores", highscores)
			hard_highscores = data.get("hard_highscores", hard_highscores)
			levels_unlocked = data.get("levels_unlocked", levels_unlocked)
			level_scores = data.get("level_scores", level_scores)
	else:
		save_highscores()

func save_level_score(level_name: String, new_score: int):
	if not level_scores.has(level_name):
		level_scores[level_name] = new_score
		save_highscores()
		return

	if new_score > level_scores[level_name]:
		level_scores[level_name] = new_score
		save_highscores()

func get_level_score(level_name: String) -> String:
	var best: int = level_scores.get(level_name, 0)
	var score_string = "000000"
	if best > 0:
		score_string = str(best)
	return score_string

func get_highscore(player: int) -> int:
	var hi_score: int = 0
	if Global.hard_mode:
		hi_score = hard_highscores.get(player - 1)
	else:
		hi_score = highscores.get(player - 1)
	return hi_score

func get_highscore_string(player: int) -> String:
	var hi_score: int = 0
	if Global.hard_mode:
		hi_score = hard_highscores.get(player - 1)
	else:
		hi_score = highscores.get(player - 1)

	var score_string = "000000"
	if hi_score > 0:
		score_string = str(hi_score)

	return score_string

func set_highscore(players: int, new_score: int):
	if Global.hard_mode:
		hard_highscores[players - 1] = new_score
	else:
		highscores[players - 1] = new_score

func new_levels_unlocked(cur_level: int):
	if levels_unlocked >= cur_level:
		return
	levels_unlocked += 1
