extends Node2D


export(String, '1', '2', '3', '4') var number = '1'
export var ready = false

export(NodePath) var player_animator
export(Array, NodePath) var others

var animator_node : AnimationPlayer
var other_players : Array


func _ready():
	$Restart.show()
	$Restart/Anim.play('Pulse')
	$Text.hide()
	
	animator_node = get_node(player_animator)
	other_players = []
	for j in others.size():
		other_players.push_back(get_node(others[j]))


func _input(event):
	if event.is_action_pressed(number + '_confirm'):
		if not ready:
			ready = true
			$Restart/Anim.stop()
			$Anim.play('Ready Up')
	elif event.is_action_pressed(number + '_cancel'):
		if ready:
			reset()


func reset():
	show()
	set_process_input(true)
	
	ready = false
	$Restart.show()
	$Restart/Anim.play('Pulse')
	$Text.hide()


func _start_game():
	for o in other_players:
		if not o.ready:
			return
	
	if $'/root/Queue'.refresh_queue:
		$'/root/Queue'.clear()
		$'/root/Queue'.refresh_queue = false
	
	animator_node.play('Start')
	for o in other_players:
		o.animator_node.play('Start')
