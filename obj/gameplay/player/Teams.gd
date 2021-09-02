extends Node


#warning-ignore:unused_class_variable
var active = []

var containers = []
var scores = []


func _ready():
	prepare()


func prepare():
	"""Reset all of the Team-related array properties."""
	active = []
	
	containers = []
	scores = []
	for j in $'/root/Colors'.frames.size():
		containers.append([])
		scores.append([])


func loss():
	"""If only one team is active, end gameplay and increment their score."""
	var remaining_team = -1
	for team in containers.size():
		for p in containers[team].size():
			if not containers[team][p].lost:
				if remaining_team < 0:
					remaining_team = team
					break
				else:
					return
	
	if remaining_team == -1:
		# TODO: implement draw game fanfare?
		return
	
	for winner in containers[remaining_team]:
		winner.set_process_input(true)
		winner.get_node('Result/Anim').play('Win')
		winner.get_node('Result/Restart/Anim').play('Pulse')
		winner.get_node('Anim').stop()
		winner.game_over = true
		if winner.active_piece:
			winner.active_piece.get_node('Anim').stop()
			winner.active_piece.get_node('Anim2').stop()
			if winner.active_piece.partner:
				winner.active_piece.partner.get_node('Anim').stop()
			winner.active_piece.set_process_input(false)
	
	for scoreboard in scores[remaining_team]:
		if not scoreboard:
			continue
		var v = int(scoreboard.get_node('Text').text) + 1
		scoreboard.get_node('Text').bbcode_text = \
			'[center]' + str(v) + '[/center]'
		# Prevent the scoreboard from flashing the new score before
		# fading in.
		scoreboard.hide()
		scoreboard.get_node('Anim').play('Increment')
	
	$'/root/Queue'.clear()
