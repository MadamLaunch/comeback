extends LobbySettingsItem


export(NodePath) var master_node


func launch_preset_name_window(_caller):
	if value == 1:
		get_tree().call_group \
			('PresetNameWindow', 'launch',
			number, get_node(master_node).color, self)


func launch_delete_preset_window():
	if value >= 2:
		get_tree().call_group \
			('PresetDeleteWindow', 'launch',
			number, get_node(master_node).color, self)


func save_preset(preset_name : String):
	"""TODO"""
	var m = get_node(master_node)
	
	var cp = ColorPreset.new()
	cp.name = preset_name
	
	var sync_group : String
	if m.color_type == 0:
		cp.data = $'/root/Colors'.block_presets[m.color][1].data.darkened(0)
		$'/root/Colors'.block_presets[m.color].push_back(cp)
		sync_group = 'blockPreset' + str(m.color)
	else:
		cp.data = $'/root/Colors'.ui_presets[m.color][1].data.darkened(0)
		$'/root/Colors'.ui_presets[m.color].push_back(cp)
		sync_group = 'uiPreset' + str(m.color)
	
	get_tree().call_group(sync_group, '_add_preset', preset_name)
	
	match m.color_type:
		0: $'/root/Colors'.save_presets('block', m.color)
		1: $'/root/Colors'.save_presets('ui', m.color)


func _add_preset(preset_name : String):
	values.push_back(preset_name)
	set_value(values.size() - 1, true)


func delete_preset():
	"""TODO"""
	var m = get_node(master_node)
	match m.color_type:
		0: $'/root/Colors'.delete_preset('block', m.color, value)
		1: $'/root/Colors'.delete_preset('ui', m.color, value)


func _remove_preset():
	values.remove(value)
	set_value(value, true)
