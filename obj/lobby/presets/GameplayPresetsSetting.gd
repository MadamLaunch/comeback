extends LobbySettingsItem


export(NodePath) var color
export(NodePath) var starting_speed
export(NodePath) var speed_increment
export(NodePath) var defense_multiplier
export(NodePath) var offense_multiplier
export(NodePath) var group_garbage_in
export(NodePath) var group_garbage_out

var value_obj = []


func _ready():
	value_obj.push_back(package_positions())


func _save_selections(number : int, _shift):
	"""TODO"""
	# Apply setting-changes before risking slow filesystem I/O.
	apply_settings(number)
	
	var customs = []
	
	for node in get_tree().get_nodes_in_group('Preset Navigator'):
		# Grab the node's custom settings, since they're saved
		# alongside the selection.
		var settings : Dictionary = node.value_obj[1].dict()
		settings['selection'] = node.value
		
		customs.push_back(settings)
	
	var customs_file : File = File.new()
	if customs_file.open('user://customs.json', File.WRITE) == OK:
		for entry in customs:
			customs_file.store_line(to_json(entry))
		customs_file.close()


func apply_settings(_number : int):
	"""TODO"""
	if _number < 0 or _number >= value_obj.size():
		return
	
	var v : GameplaySettings = value_obj[_number]
	
	#_assign(color, v.color, true)
	
	_assign(starting_speed, int(v.starting_speed))
	_assign(speed_increment, int(v.speed_increment))
	_assign(defense_multiplier, int(v.defense_multiplier))
	_assign(offense_multiplier, int(v.offense_multiplier))
	
	_assign(group_garbage_in, v.group_garbage_in)
	_assign(group_garbage_out, v.group_garbage_out)


func _assign(path : NodePath, _value : int, signal_change = false):
	var node : LobbySettingsItem = get_node(path)
	node.set_value(_value)
	
	if signal_change:
		for s in node.get_signal_connection_list('setting_changed'):
			if s.target != self:
				s.target.call(s.method, node.value)


func package_settings():
	"""TODO"""
	var settings = GameplaySettings.new()
	
	settings.number = int(number)
	settings.color = get_node(color).value
	
	settings.starting_speed = float(_value(starting_speed))
	settings.speed_increment = float(_value(speed_increment)) * .01
	settings.defense_multiplier = float(_value(defense_multiplier))
	settings.offense_multiplier = float(_value(offense_multiplier))
	
	settings.group_garbage_in = get_node(group_garbage_in).value
	settings.group_garbage_out = get_node(group_garbage_out).value + 1
	
	return settings


func _value(path : NodePath):
	var node = get_node(path)
	return node.values[node.value]


func package_positions():
	"""TODO"""
	var settings = GameplaySettings.new()
	
	settings.number = number
	
	settings.color = get_node(color).value
	settings.starting_speed = get_node(starting_speed).value
	settings.speed_increment = get_node(speed_increment).value
	settings.defense_multiplier = get_node(defense_multiplier).value
	settings.offense_multiplier = get_node(offense_multiplier).value
	settings.group_garbage_in = get_node(group_garbage_in).value
	settings.group_garbage_out = get_node(group_garbage_out).value
	
	return settings


func rebuild_customs(_number, _shift):
	"""TODO"""
	value_obj[1].free()
	value_obj[1] = package_positions()
	set_value(1, true)


func launch_preset_name_window(_caller):
	if value == 1:
		get_tree().call_group \
			('PresetNameWindow', 'launch',
			number, get_node(color).value, self)


func launch_delete_preset_window():
	if value >= 2:
		get_tree().call_group \
			('PresetDeleteWindow', 'launch',
			number, get_node(color).value, self)


func save_preset(preset_name : String):
	"""TODO"""
	$'/root/Presets'.add \
		(package_positions(), preset_name)
	$'/root/Presets'.save()
	set_value(values.size() - 1, true)


func delete_preset():
	"""TODO"""
	$'/root/Presets'.remove(value - 2)
	$'/root/Presets'.save()
	set_value(value, true)
