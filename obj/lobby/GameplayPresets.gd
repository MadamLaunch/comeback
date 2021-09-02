extends Node


# REMEMBER! "Custom" is per-number, saved presets are universal.
# If number is 0, propagate through group; else save specifically?
var presets = []
var labels = []


func add(new_preset, label):
	"""TODO"""
	presets.push_back(new_preset)
	labels.push_back(label)
	
	for node in get_tree().get_nodes_in_group('Preset Navigator'):
		node.value_obj.push_back(new_preset)
		node.values.push_back(label)


func remove(position):
	"""TODO"""
	presets.remove(position)
	labels.remove(position)
	
	for node in get_tree().get_nodes_in_group('Preset Navigator'):
		node.value_obj.remove(position + 2)
		node.values.remove(position + 2)


func save():
	"""TODO"""
	var presets_file : File = File.new()
	if presets_file.open('user://presets.json', File.WRITE) == OK:
		for j in labels.size():
			var entry : Dictionary = presets[j].dict()
			entry['label'] = labels[j]
			# warning-ignore:return_value_discarded
			entry.erase('color')
			# warning-ignore:return_value_discarded
			entry.erase('number')
			presets_file.store_line(to_json(entry))
		presets_file.close()
