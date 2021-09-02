extends Node2D
class_name Player


export(int, 0, 6) var color
export(String, '1', '2', '3', '4') var number = '1'

export(NodePath) var pattern_selector


func get_class():
	return 'Player'


func is_class(type):
	return type == 'Player' or .is_class(type)


func _ready():
	"""The property-setting here is effectively for testing, now."""
	set_color()
	$PlayArea/VC/V/BlockContainer.number = number
	$PlayArea/VC/V/BlockContainer/Cursor.number = number
	
	if not pattern_selector:
		$PlayArea/Ready.number = number
	
	#warning-ignore:return_value_discarded
	$PlayArea/VC/V/BlockContainer.connect('reset', self, 'reset')
	# This is done to prevent needing to edit PlayArea children in
	# every GameMode scene.


func _input(event):
	if event.is_action_pressed('1_test') and false:
		#$'../Anim'.stop()
		#$'../Anim'.play('Intro')
		get_tree().paused = not get_tree().paused
		var p = get_tree().paused
		for n in get_tree().get_nodes_in_group('HideOnPause'):
			if p:
				n.hide()
			else:
				n.show()


func apply_settings(settings : GameplaySettings):
	number = str(settings.number)
	if pattern_selector:
		get_node(pattern_selector).number = number
	else:
		$PlayArea/Ready.number = number
	
	$PlayArea/VC/V/BlockContainer.apply_settings(settings)
	set_color(settings.color)


func set_color(c=null):
	"""Apply a palette color to key components of the PlayArea."""
	# Default to what was set within the editor, for unit testing.
	if c == null:
		c = color
	else:
		color = c
	
	c = $'/root/Colors'.ui[c]
	
	$PlayArea/Outline.self_modulate = c
	
	# This is for components unique to the 1v1 gameplay Scene.
	if has_node('Pattern'):
		$Pattern.self_modulate = c
		$Pattern/Footer.self_modulate = c
	
	if has_node('Preview'):
		$Preview/Outline.self_modulate = c
	
	if has_node('Preview/Score'):
		$Preview/Score.self_modulate = c
	elif has_node('Score'):
		$Score.self_modulate = c
	
	if has_node('Preview/Stats'):
		for child in $Preview/Stats.get_children():
			child.self_modulate = c
	elif has_node('Stats'):
		for child in $Stats.get_children():
			child.self_modulate = c
	
	$'/root/Teams'.containers[color].append($PlayArea/VC/V/BlockContainer)
	$PlayArea/VC/V/BlockContainer.color = color
	
	if $Preview.has_node('Stats'):
		$'/root/Teams'.scores[color].append($Preview/Stats/Score)
	else:
		$'/root/Teams'.scores[color].append($Preview/Score/Number)


func reset():
	"""TODO"""
	$PlayArea/VC/V/BlockContainer.clear()
	$PlayArea/VC/V/BlockContainer/Result.hide()
	$PlayArea/VC/V/BlockContainer.set_process(false)
	$PlayArea/VC/V/BlockContainer.set_process_input(false)
	
	if pattern_selector:
		get_node(pattern_selector).toggle_ready(true)
		$Preview.clear()
	else:
		$PlayArea/Ready.reset()
		$Preview.clear()
