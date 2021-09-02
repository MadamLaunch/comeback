extends Object
class_name GameplaySettings


var number : int
var color : int
var starting_speed : float = 1
var speed_increment : float = .015
var defense_multiplier : float = 1
var offense_multiplier : float = 1

enum GarbageType {
	NORMAL = 0,
	ALL_BLACK,
	ALL_WHITE,
	ALL_COLORS
}

var group_garbage_in = GarbageType.NORMAL
var group_garbage_out = GarbageType.ALL_COLORS


func dict():
	return {
		'number': number,
		'color': color,
		'starting speed': starting_speed,
		'speed increment': speed_increment,
		'defense multiplier': defense_multiplier,
		'offense multiplier': offense_multiplier,
		'group garbage in': group_garbage_in,
		'group garbage out': group_garbage_out
	}


func load_property(dictionary : Dictionary, key : String):
	if dictionary.has(key):
		var k = int(dictionary[key])
		match key:
			'number':
				number = k
			'color':
				color = k
			'starting speed':
				starting_speed = k
			'speed increment':
				speed_increment = k
			'defense multiplier':
				defense_multiplier = k
			'offense multiplier':
				offense_multiplier = k
			'group garbage in':
				group_garbage_in = k
			'group garbage out':
				group_garbage_out = k


func load_properties(dictionary : Dictionary):
	for key in dictionary.keys():
		var k = int(dictionary[key])
		match key:
			'number':
				number = k
			'color':
				color = k
			'starting speed':
				starting_speed = k
			'speed increment':
				speed_increment = k
			'defense multiplier':
				defense_multiplier = k
			'offense multiplier':
				offense_multiplier = k
			'group garbage in':
				group_garbage_in = k
			'group garbage out':
				group_garbage_out = k
