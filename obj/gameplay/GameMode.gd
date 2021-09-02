extends Node2D
class_name GameMode


var players
var numbers = []
var colors = [0, 0, 0, 0]

var endurance_mode = false


func _ready():
	$'/root/Queue'.clear()
	
	if not endurance_mode:
		for stats in get_tree().get_nodes_in_group('Optional Stats'):
			stats.hide()


func _players():
	var c = get_children()
	# Account for 3+ player modes isolating Players in a container.
	if has_node('Players'):
		c = $Players.get_children()
	
	var children = []
	for _c in c:
		if _c is Player:
			children.push_back(_c)
	return children


func apply_settings(settings : Array):
	"""TODO"""
	$'/root/Teams'.prepare()
	
	var children = _players()
	var teams = {}
	
	for j in children.size():
		if j >= settings.size():
			break
		
		children[j].apply_settings(settings[j])
		# Keep a note of each Player's color.
		if not teams.has(settings[j].color):
			teams[settings[j].color] = []
		teams[settings[j].color].push_back(children[j])
		
		colors[settings[j].number - 1] = settings[j].color
	
	# Store the Player nodes using their color designations.
	var containers = get_tree().get_nodes_in_group('BlockContainer')
	if teams.keys().size() == 1:
		players = []
		for container in containers:
			if container.game_mode == self:
				players.push_back(container)
				numbers.push_back(container.number)
	else:
		players = {}
		for container in containers:
			if container.game_mode != self:
				continue
			if not players.has(container.color):
				players[container.color] = []
			players[container.color].push_back(container)
			numbers.push_back(container.number)


func send_garbage(color, number, amount, modifier = 0):
	"""TODO"""
	if endurance_mode:
		return
	
	if players is Array:
		for container in players:
			if container.number != number:
				container.add_garbage(amount, modifier)
	elif players is Dictionary:
		for c in players.keys():
			if c != color:
				for container in players[c]:
					container.add_garbage(amount, modifier)


func report_loss(caller):
	"""TODO"""
	var reaction : int = 0
	
	var winner = null
	var multiple_winners = false
	if players is Array:
		# If there is more than one player still active, skip further
		# calculations.
		for p in players:
			if not p.lost:
				if not winner:
					winner = p
				else:
					winner = null
					multiple_winners = true
					break
		
		# Halt the winner's gamestate, and return the lose flag if
		# necessary.
		if not endurance_mode:
			# In a garbage-versus single-color FFA, someone reporting a
			# loss will never have a chance to win, by design.
			if winner:
				winner.win()
			
			reaction = -1
		# Only calculate a final winner in a score-attack/endurance
		# mode when everybody is done playing.
		elif not winner and not multiple_winners:
			# A reaction flag of zero is returned because this method
			# induces all necessary reactions on its own.
			_calculate_scores_array()
	elif players is Dictionary:
		# If there is more than one player still active, skip further
		# calculations.
		for color in players.keys():
			if multiple_winners:
				winner = null
				break
			
			var team = players[color]
			for p in team:
				if not p.lost:
					if not winner:
						winner = team
						break
					else:
						multiple_winners = true
						break
		
		if not endurance_mode:
			if winner:
				reaction = -1
				for player in winner:
					if caller == player:
						reaction = 0
					# Even if the player had previously lost, fuck it,
					# their TEAM won~!
					player.win()
			else:
				reaction = -1
		# Only calculate a final winner when everybody is done playing.
		elif not winner and not multiple_winners:
			# A reaction flag of zero is returned because this method
			# induces all necessary reactions on its own.
			_calculate_scores_dict()
	
	return reaction


func _calculate_scores_array():
	var winner
	var score = -1
	
	for p in players:
		if p.score > score:
			score = p.score
			winner = p
		elif p.score == score:
			if not winner is Array:
				winner = [winner, p]
			else:
				winner.push_back(p)
	
	if not winner is Array:
		for p in players:
			if p != winner:
				p.lose()
		winner.win()
	else:
		for p in players:
			if p in winner:
				p.win()
			else:
				p.lose()


func _calculate_scores_dict():
	var winners = []
	var score = -1
	
	for color in players.keys():
		var team = players[color]
		# Calculate the cumulative score of the whole team.
		var team_score = 0
		for p in team:
			team_score += p.score
		
		# Replace the inevitable array of winners with a new one.
		if team_score > score:
			winners = team
			score = team_score
		# Append the current team to the saved array.
		elif team_score == score:
			winners = winners + team
	
	if winners.size() > 0:
		for color in players.keys():
			for player in players[color]:
				if player in winners:
					player.win()
				else:
					player.lose()
		
		$'/root/Queue'.refresh_queue = true


func reset():
	"""Call `reset()` in all child Players."""
	for p in _players():
		p.reset()


func quit():
	"""Free the GameMode and re-awaken the main menu."""
	get_tree().paused = false
	get_tree().call_group('Menu System', 'awaken')
	queue_free()
	
	for n in get_tree().get_nodes_in_group('HideOnPause'):
		n.show()


func clear_queue():
	if $'/root/Queue'.refresh_queue:
		$'/root/Queue'.clear()
