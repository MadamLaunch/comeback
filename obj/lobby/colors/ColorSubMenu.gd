extends LobbySettingsSubMenu


export(Array, NodePath) var previews
export(NodePath) var presets_node
var presets : LobbySettingsItem

export(int, 'Blocks', 'UI') var color_type

var color : int = 0


func _ready():
	presets = get_node(presets_node)
	
	load_presets(0)
	
	# Initially set the menu-color previews.
	# They are updated alongside the actual menus when changes happen.
	if color_type == 1:
		for p in range(previews.size()):
			var node = get_node(previews[p])
			node.color = $'/root/Colors'.ui[p]


func update_color(index : int, update_custom = true):
	"""Set the color of the specified preview nodes to match the
	current global color-value set.
	
	Arguments:
	index -- the color within the Colors singleton to reference; turns
		into saved value `color` if value is -1
	update_custom -- whether or not to save the new color to the
		Color singleton's presets in the 'custom' slot (default: true)
	
	This method is called by ColorSliders when manipulated by
	themselves, wherein `update_custom` is true; when cycling
	through presets, wherein the value is false; and when initializing,
	wherein again it is false.
	"""
	for p in previews:
		var preview = get_node(p)
		# Ghost previews have to specify if they're Blocks or Triggers.
		if preview is Ghost:
			if preview.name.ends_with('1'):
				preview.set_color(index, 0)
			else:
				preview.set_color(index, 1)
		elif preview is Block:
			preview.set_color(index)
	# Since the UI previews are updated via group-manipulation, this
	# code is no longer necessary. I'm keeping it around JUST in case.
	#	elif preview.name.ends_with(str(index + 1)):
	#		match color_type:
	#			0: preview.color = $'/root/Colors'.blocks[index]
	#			1: preview.color = $'/root/Colors'.ui[index]
	
	if update_custom:
		if color_type == 0:
			$'/root/Colors'.block_presets[color][1].data \
				= Color($'/root/Colors'.blocks[index])
			$'/root/Colors'.block_preset_selected[color] = 1
			# Save changes to file.
			$'/root/Colors'.save_presets('block', color)
		else:
			$'/root/Colors'.ui_presets[color][1].data \
				= Color($'/root/Colors'.ui[index])
			$'/root/Colors'.ui_preset_selected[color] = 1
			# Save changes to file.
			$'/root/Colors'.save_presets('ui', color)
		
		# Shift to "Custom", since that preset is being manipulated.
		presets.set_value(1)
		$'/root/Colors'.save_preset_selection()
	
	# Update not only the menu-backgrounds but also the previews.
	if color_type == 1:
		for n in get_tree().get_nodes_in_group('Background' + str(index)):
			n.color = $'/root/Colors'.ui[index]


func load_presets(color_index : int, _shift = 0):
	"""Re-load values into the menu-item for presets, and re-
	
	Arguments:
	color_index -- which color to start referencing from the Colors
		singleton
	_shift -- ignored; included to allow this method to be attached to
		ColorSelector's `setting_changed`-signal
	
	This method is called by ColorSelector, whenever it is cycled
	through, and when the sub-menu is initialized.
	"""
	# Synchronize the presets-item to the new active color.
	var group: String
	match color_type:
		0: group = 'block'
		1: group = 'ui'
	presets.remove_from_group(group + 'Preset' + str(color))
	presets.add_to_group(group + 'Preset' + str(color_index))
	
	color = color_index
	
	var objects : Array
	var selections : Array
	if color_type == 0: # Blocks
		objects = $'/root/Colors'.block_presets
		selections = $'/root/Colors'.block_preset_selected
	else: # UI
		objects = $'/root/Colors'.ui_presets
		selections = $'/root/Colors'.ui_preset_selected
	
	# Clear and re-populate the presets.
	presets.values.clear()
	for p in objects[color]:
		presets.values.push_back(p.name)
	
	# Manipulate the presets-item, and by-extension also the sliders
	# and previews of the sub-menu.
	# This method will lead to a redundant call to `update_color()`
	# within any synchronized ColorSubMenus, in case you're wondering.
	presets.set_value(selections[color], true)


func save_preset_selection(preset_index : int, _shift = 0):
	"""Update every synchronized sub-menu to match the selected preset,
	and save the selection-index into the Colors singleton.
	
	Arguments:
	preset_index -- which preset to apply from the Colors singleton's
	2D array of presets
	_shift -- ignored; included to allow this method to be connected to
	the LobbySettingsItem for preset's `setting_changed`-signal
	
	This method is only called when cycling through presets.
	"""
	if color_type == 0: # Blocks
		# Prevent an infinite synchronization-loop by simply updating
		# and stopping if the sub-menu has already been made to match
		# the Colors singleton's selected preset for the active color.
		if $'/root/Colors'.block_preset_selected[color] == preset_index:
			update_color(color, false)
			return
		
		# Set the game's operating standard to the current preset.
		$'/root/Colors'.blocks[color] \
			= $'/root/Colors'.block_presets[color][preset_index].data.to_html()
		$'/root/Colors'.block_preset_selected[color] = preset_index
	else: # UI
		# Prevent an infinite synchronization-loop by simply updating
		# and stopping if the sub-menu has already been made to match
		# the Colors singleton's selected preset for the active color.
		if $'/root/Colors'.ui_preset_selected[color] == preset_index:
			update_color(color, false)
			return
		
		# Set the game's operating standard to the current preset.
		$'/root/Colors'.ui[color] \
			= $'/root/Colors'.ui_presets[color][preset_index].data.to_html()
		$'/root/Colors'.ui_preset_selected[color] = preset_index
	
	# This point is only reached by the sub-menu that was manipulated
	# by a user: anyone synchronizing is stopped above.
	update_color(color, false)
	
	# Synchronize any other sub-menu's presets-setting currently
	# loaded with the same color, which will in-turn update its
	# ColorSliders and previews.
	var group: String
	match color_type:
		0: group = 'block'
		1: group = 'ui'
	get_tree().call_group \
		(group + 'Preset' + str(color), 'set_value', presets.value, true)
	
	# Save the change in selections to a file.
	$'/root/Colors'.save_preset_selection()
