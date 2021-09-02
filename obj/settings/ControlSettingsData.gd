extends Node


# warning-ignore:unused_class_variable
var relative_rotation = [0, 0, 0, 0]
# warning-ignore:unused_class_variable
var default_controls = {}


func _ready():
	_set_defaults()
	
	var controls = File.new()
	if not controls.file_exists('user://controls.json'):
		save()
	
	controls.open('user://controls.json', File.READ)
	while controls.get_position() < controls.get_len():
		var file = parse_json(controls.get_line())
		InputMap.action_erase_events(file['action'])
		
		var key = InputEventKey.new()
		var k = int(file['key'])
		if k >= 0:
			key.scancode = int(file['key'])
			InputMap.action_add_event(file['action'], key)
		
		var pad = InputEventJoypadButton.new()
		var p = int(file['pad'])
		if p >= 0:
			pad.device = int(file['device'])
			pad.button_index = int(file['pad'])
			InputMap.action_add_event(file['action'], pad)
	controls.close()
	
	var rotations = File.new()
	if not rotations.file_exists('user://controls.json'):
		save()
	
	rotations.open('user://rotations.json', File.READ)
	relative_rotation = parse_json(rotations.get_line())
	rotations.close()
	


func save():
	var controls = File.new()
	controls.open('user://controls.json', File.WRITE)
	
	for action in InputMap.get_actions():
		var key = -1
		var pad = -1
		var device = -1
		for event in InputMap.get_action_list(action):
			if event is InputEventKey:
				key = event.scancode
			elif event is InputEventJoypadButton:
				pad = event.button_index
				device = event.device
		
		var dict = {
			'action': action,
			'key': key,
			'pad': pad,
			'device': device}
		controls.store_line(to_json(dict))
	
	controls.close()
	
	var rotations = File.new()
	rotations.open('user://rotations.json', File.WRITE)
	rotations.store_line(to_json(relative_rotation))
	rotations.close()


func _set_defaults():
	for action in InputMap.get_actions():
		default_controls[action] = []
		for event in InputMap.get_action_list(action):
			default_controls[action].push_back(event)
