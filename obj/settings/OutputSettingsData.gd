extends Node


var SFX_BUS = AudioServer.get_bus_index('SFX')
var MUSIC_BUS = AudioServer.get_bus_index('Music')


func _ready():
	_color_presets('blocks')
	_color_presets('ui')
	_volume()


func _color_presets(category):
	var colors = File.new()
	if not colors.file_exists('user://' + category + '.json'):
		return
	
	colors.open('user://' + category + '.json', File.READ)
	var file = parse_json(colors.get_line())
	
	for j in range(len($'/root/Colors'.get(category))):
		$'/root/Colors'.get(category)[j] = file['set'][j]
#	for c in get_tree().get_nodes_in_group(group):
#		var picker = c.get_node('ColorPickerButton').get_picker()
#		for preset in file[str(c.color)]:
#			picker.add_preset(Color(preset))
#		picker.color = Color(file['set'][c.color])
		
#		c.get_node('ColorPickerButton').color = picker.color
#		c.set_by_file = true
		
#		$'/root/Colors'.get(get)[c.color] = picker.color


func save_color_presets(category):
	var colors = File.new()
	colors.open('user://' + category + '.json', File.WRITE)
	
	var dict = {}
	dict['set'] = $'/root/Colors'.get(category)
#	for c in get_tree().get_nodes_in_group(group):
#		var picker = c.get_node('ColorPickerButton').get_picker()
#		dict[c.color] = [$'/root/Colors'.get('default_' + get)[c.color]]
#		for p in picker.get_presets():
#			var block = p.to_html(false)
#			if not hex in dict[c.color]:
#				dict[c.color].append(hex)
#		dict['set'].append(str(picker.color.to_html(false)))
	
	colors.store_line(to_json(dict))
	colors.close()


func _volume():
	var volume = File.new()
	if not volume.file_exists('user://volume.json'):
		return
	
	volume.open('user://volume.json', File.READ)
	var file = parse_json(volume.get_line())
	
	AudioServer.set_bus_volume_db(SFX_BUS, linear2db(float(file['sfx'])))
	AudioServer.set_bus_volume_db(MUSIC_BUS, linear2db(float(file['music'])))


func save_volume():
	var volume = File.new()
	volume.open('user://volume.json', File.WRITE)
	
	var dict = {}
	dict['sfx'] = db2linear(AudioServer.get_bus_volume_db(SFX_BUS))
	dict['music'] = db2linear(AudioServer.get_bus_volume_db(MUSIC_BUS))
	volume.store_line(to_json(dict))
	volume.close()
