extends Node2D


export(NodePath) var game_mode
var _game_mode = null

var number = ''


func _ready():
	_game_mode = get_node(game_mode)
	
	var first: PauseMenuItem
	var previous : PauseMenuItem
	
	for item in $Container.get_children():
		if not item is PauseMenuItem:
			continue
		
		if previous:
			previous.below = item
			item.above = previous
		else:
			first = item
		previous = item
	
	previous.below = first
	first.above = previous


func _input(event):
	if not event.is_action_type():
		return
	
	# Check every player's input map.
	# Every player can un-pause, but only the pausing player can
	# navigate the PauseMenu.
	for j in _game_mode.numbers:
		if event.is_action_pressed(j + '_pause'):
			get_tree().paused = not get_tree().paused
			# Conceal all gameplay-related objects while paused.
			var p = get_tree().paused
			for n in get_tree().get_nodes_in_group('HideOnPause'):
				if p:
					_show(j)
					n.hide()
				else:
					_hide()
					n.show()
			break


func _show(player : String):
	"""Assign a player to control the PauseMenu; launch.
	
	Arguments:
	player -- the number of the player as a string"""
	number = player
	
	$Outline.modulate = \
		$'/root/Colors'.ui[_game_mode.colors[int(player) - 1]]
	$Container/Header.text = 'p' + number + ' paused'
	$Container/Continue.activate()
	
	get_tree().call_group('PauseMenuItem', 'assign_number', number)
	show()


func _hide():
	"""Deactivate every item in the menu; hide."""
	# PROTIP: You can't send null as an argument by this method: it'll
	# just get dropped... or something.
	get_tree().call_group('PauseMenuItem', 'deactivate')
	hide()


func continue_game():
	"""Show all gameplay-related objects and resume the game."""
	# Delaying un-pausing prevents the confirmation-input from being
	# read by anything related to gameplay.
	call_deferred('_unpause')
	
	_hide()
	for n in get_tree().get_nodes_in_group('HideOnPause'):
		n.show()


func reset(new_queue=false):
	"""Tell the parent GameMode to reset; un-pause.
	
	Arguments:
	new_queue -- whether or not to clear the Queue singleton
		(default: false)
	
	By default, the Queue will be preserved, allowing the same pieces
	to be re-used in the same order.
	"""
	# Delaying un-pausing prevents the confirmation-input from being
	# read by anything related to gameplay.
	call_deferred('_unpause')
	
	_game_mode.reset()
	if new_queue:
		$'/root/Queue'.refresh_queue = true
	else:
		$'/root/Queue'.refresh_queue = false
	
	_hide()
	for n in get_tree().get_nodes_in_group('HideOnPause'):
		n.show()


func _unpause():
	get_tree().paused = false


func quit():
	"""Play base menu's intro animations; free parent afterwards."""
	#$'../../Players'.animate('Intro')
	#$'/root/Lobby'.SETTINGS_BUTTON.enter()
	#$Anim.play('Free')
	_game_mode.call_deferred('quit')


func _free():
	get_tree().paused = false # Make sure things can run again~
	$'..'.queue_free()
