extends Node2D


const SINGLE_PLAYER = preload('res://scenes/Gameplay1.tscn')
const DUEL = preload('res://scenes/Gameplay2a.tscn')
const ENDURANCE = preload('res://scenes/Gameplay2b.tscn')
const THREE_PLAYER = preload('res://scenes/Gameplay3.tscn')
const FOUR_PLAYER = preload('res://scenes/Gameplay4.tscn')

var menus = []


func _ready():
	var offset = 0
	for menu in get_children():
		if menu is LobbySettingsMenu \
				and menu.visible:
			menus.push_back(menu)
			offset += menu.rect_size.x / 2
	
	position.x \
		= ProjectSettings.get_setting('display/window/size/width') / 2 \
		- offset
	
	call_deferred('_load_presets')
	call_deferred('_load_sound_settings')


func _load_presets():
	"""Load the JSON files containing saved gameplay settings."""
	var customs = {}
	var selections = {}
	
	# Load the "custom"-preset for each player, if they've been saved.
	var customs_file : File = File.new()
	if customs_file.file_exists('user://customs.json') \
			and customs_file.open('user://customs.json', File.READ) == OK:
		# Load and read lines one-by-one.
		while customs_file.get_position() < customs_file.get_len():
			var line = parse_json(customs_file.get_line())
			if not line is Dictionary:
				continue
			
			# Read the line into the object.
			# TODO: delete `GameplaySettings.load_property()`?
			var preset = GameplaySettings.new()
			preset.load_properties(line);
			
			# Save the GameplaySettings for assignment later.
			customs[str(preset.number)] = preset
			selections[str(line['number'])] = line['selection']
		customs_file.close()
	
	var presets = []
	var labels = []
	
	# Load all the saved presets.
	var presets_file : File = File.new()
	if presets_file.file_exists('user://presets.json') \
			and presets_file.open('user://presets.json', File.READ) == OK:
		# Load and read lines one-by-one.
		while presets_file.get_position() < presets_file.get_len():
			var line = parse_json(presets_file.get_line())
			if not line is Dictionary:
				continue
			
			# Read the line into the object.
			# TODO: delete `GameplaySettings.load_property()`?
			var preset = GameplaySettings.new()
			preset.load_properties(line);
			
			presets.push_back(preset)
			labels.push_back(line['label'])
		presets_file.close()
	
	# Save the loaded data into the singleton for them.
	$'/root/Presets'.presets = presets
	$'/root/Presets'.labels = labels
	
	# Inject all the loaded data into each menu's preset navigator.
	for node in get_tree().get_nodes_in_group('Preset Navigator'):
		# Assign any saved custom presets to their menu node's presets.
		if customs.has(node.number):
			node.value_obj.push_back(customs[node.number])
		else:
			node.value_obj.push_back(GameplaySettings.new())
		
		# Add all the saved presets to the preset navigator.
		node.value_obj += presets
		node.values += labels
		
		# Set each navigator to their previously-held position.
		if selections.has(node.number) \
				and selections[node.number] != 0:
			# Spare the system from re-writing the file it just loaded.
			node.set_value(selections[node.number])
			node.apply_settings(selections[node.number])


func _load_sound_settings():
	"""Set the volume sliders to the linear value of the audio buses."""
	var sfx = db2linear \
		(AudioServer.get_bus_volume_db($'/root/Settings'.get('SFX_BUS')))
	get_tree().call_group('SFX_BUS', 'set_value', sfx, false, true)
	
	var music = db2linear \
		(AudioServer.get_bus_volume_db($'/root/Settings'.get('MUSIC_BUS')))
	get_tree().call_group('MUSIC_BUS', 'set_value', music, false, true)


func reorder(caller, new_position, shift):
	"""Move a given LobbySettingsMenu around in their list.
	
	Arguments:
	caller -- The LobbySettingsMenu that is changing position
	new_position -- Where the menu node ought to be ordered
	shift -- The direction the menu node moved in (1 or -1)
	"""
	# Contain the caller within the bounds of the menu.
	# Correction depends on how the caller moved, not where it's
	# positioned.
	if new_position >= menus.size():
		if shift == 1:
			new_position = 0
		elif shift == -1:
			new_position = menus.size() - 1
	
	caller.set_order(new_position)
	
	# Adjust the other LobbySettingMenu nodes around the change.
	for menu in menus:
		if menu == caller:
			continue
		
		if menu.order() == new_position:
			var new_order = menu.order() - shift
			
			if new_order < 0:
				menu.set_order(menus.size() - 1)
			elif new_order >= menus.size():
				menu.set_order(0)
			else:
				menu.set_order(new_order)


func start_game():
	"""Instantiate, initialize, and launch an appropriate GameMode."""
	# Sort the LobbySettingsMenu nodes by their x-values.
	menus.sort_custom(self, '_sort_menus')
	
	var ready_players = []
	for m in menus:
		m.set_process_input(false)
		if not m.visible or not m.ready:
			continue
		ready_players.push_back(m.settings)
	
	# Basically the inverse of `awaken()`, but the `hide()` call is at
	# the end of the method for some reason.
	# Probaby disabling input first out of fear of load times?
	get_tree().call_group('LobbySettingsItem', 'hibernate')
	
	# Create the appropriate gameplay node.
	var game_mode : GameMode
	
	if ready_players.size() == 1:
		game_mode = SINGLE_PLAYER.instance()
	else:
		var endurance_only = true
		# Determine if anyone will receive garbage from anyone else.
		for j in ready_players.size():
			var p1 : GameplaySettings = ready_players[j]
			
			var k = j + 1
			while k < ready_players.size():
				var p2 : GameplaySettings = ready_players[k]
				
				if p1.offense_multiplier * p2.defense_multiplier \
						or p2.offense_multiplier * p1.defense_multiplier:
					endurance_only = false
					break
				
				k += 1
			
			if not endurance_only:
				break
		
		match ready_players.size():
			2:
				for rp in ready_players:
					rp.group_garbage_in = 0
					rp.group_garbage_out = 0
				
				if endurance_only:
					game_mode = ENDURANCE.instance()
					game_mode.endurance_mode = true
				else:
					game_mode = DUEL.instance()
			3:
				game_mode = THREE_PLAYER.instance()
				if endurance_only:
					game_mode.endurance_mode = true
			4:
				game_mode = FOUR_PLAYER.instance()
				if endurance_only:
					game_mode.endurance_mode = true
	
	# Finally hide the LobbySettings after the gameplay is instantiated.
	hide()
	
	# Attach the gameplay node to the application root and initialize it.
	$'..'.add_child(game_mode)
	game_mode.apply_settings(ready_players)


func _sort_menus(a : LobbySettingsMenu, b : LobbySettingsMenu):
	"""Compare the `rect_position.x` values of two LobbySettingsMenus."""
	return a.rect_position.x < b.rect_position.x


func awaken():
	"""Show the LobbySettings and re-awaken all contained menu nodes."""
	for m in menus:
		m.set_process_input(m.visible)
		if m.ready:
			m.set_ready(null, false)
	
	show()
	get_tree().call_group('LobbySettingsItem', 'awaken')
