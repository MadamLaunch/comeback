extends Node


const names = \
	['blue', 'yellow', 'red', 'green', 'purple', 'black', 'white']
const names_caps = \
	['Blue', 'Yellow', 'Red', 'Green', 'Purple', 'Black', 'White']
const names_upper = \
	['BLUE', 'YELLOW', 'RED', 'GREEN', 'PURPLE', 'BLACK', 'WHITE']

const frames = [0, 1, 2, 3, 4, 5, 5]

const default_blocks = \
	['00d5ff', 'ffff00', 'ff0000', '1de41d', 'ff49ff', '4e4e4e', 'ffffff']
const default_ui = \
	['0081ff', 'e3e300', 'e22e2e', '5ad35a', 'e341e3', '555555', 'c9c9c9']

var blocks = \
	['00d5ff', 'ffff00', 'ff0000', '1de41d', 'ff49ff', '4e4e4e', 'ffffff']
var ui = \
	['0081ff', 'e3e300', 'e22e2e', '5ad35a', 'e341e3', '555555', 'c9c9c9']

var block_presets = [[], [], [], [], [], [], []]
var ui_presets = [[], [], [], [], [], [], []]

var block_preset_selected = [0, 0, 0, 0, 0, 0, 0]
var ui_preset_selected = [0, 0, 0, 0, 0, 0, 0]


func _ready():
	for j in range(7):
		_load_presets('block', j)
		_load_presets('ui', j)
	
	# Load the saved selections for each color.
	var selections_file : File = File.new()
	if selections_file.file_exists('user://color_selections.json') \
			and selections_file.open \
				('user://color_selections.json', File.READ) == OK:
		block_preset_selected = parse_json(selections_file.get_line())
		ui_preset_selected = parse_json(selections_file.get_line())
	
	# Apply the saved selection to the operating color values.
	for j in range(7):
		# Just a little crash-prevention~
		# Might not be needed once development's knocked out~
		if block_preset_selected[j] > block_presets[j].size():
			block_preset_selected[j] = 0
		if ui_preset_selected[j] > ui_presets[j].size():
			ui_preset_selected[j] = 0
		
		blocks[j] = block_presets[j][block_preset_selected[j]] \
			.data.to_html(false)
		ui[j] = ui_presets[j][ui_preset_selected[j]] \
			.data.to_html(false)


func _load_presets(color_type, index):
	"""TODO"""
	var file_name = 'user://' + color_type + '_' + names[index] + '.json'
	var color_file : File = File.new()
	
	if color_file.file_exists(file_name) \
			and color_file.open(file_name, File.READ) == OK:
		while color_file.get_position() < color_file.get_len():
			var file = parse_json(color_file.get_line())
			if not file is Dictionary:
				continue
			
			var color = ColorPreset.new()
			color.name = file['name']
			color.data = Color(file['data'])
			
			match color_type:
				'block': block_presets[index].push_back(color)
				'ui': ui_presets[index].push_back(color)
	else:
		var defaults : Array
		match color_type:
			'block': defaults = default_blocks
			'ui': defaults = default_ui
		
		for _k in range(2):
			var c = ColorPreset.new()
			c .data = Color(defaults[index])
			match color_type:
				'block': block_presets[index].push_back(c)
				'ui': ui_presets[index].push_back(c)
		
		match color_type:
			'block':
				block_presets[index][0].name = 'Default'
				block_presets[index][1].name = 'Custom'
			'ui':
				ui_presets[index][0].name = 'Default'
				ui_presets[index][1].name = 'Custom'


func save_presets(color_type, index):
	"""TODO"""
	var file_name = 'user://' + color_type + '_' + names[index] + '.json'
	var color_file : File = File.new()
	
	if color_file.open(file_name, File.WRITE) == OK:
		match color_type:
			'block':
				for cp in block_presets[index]:
					color_file.store_line(to_json(cp.to_dict()))
			'ui':
				for cp in ui_presets[index]:
					color_file.store_line(to_json(cp.to_dict()))


func save_preset_selection():
	"""TODO"""
	var selections_file : File = File.new()
	if selections_file.open \
			('user://color_selections.json', File.WRITE) == OK:
		selections_file.store_line(to_json(block_preset_selected))
		selections_file.store_line(to_json(ui_preset_selected))


func delete_preset(color_type, color_index, preset_index):
	"""TODO"""
	var sync_group : String
	match color_type:
		'block':
			block_presets[color_index].remove(preset_index)
			sync_group = 'blockPreset' + str(color_index)
		'ui':
			ui_presets[color_index].remove(preset_index)
			sync_group = 'uiPreset' + str(color_index)
	
	get_tree().call_group(sync_group, '_remove_preset')
	save_presets(color_type, color_index)
