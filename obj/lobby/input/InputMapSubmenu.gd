extends Node


const GAMEPAD_TEXTURES = [
	preload('res://obj/lobby/input/gamepad/0.svg'),
	preload('res://obj/lobby/input/gamepad/1.svg'),
	preload('res://obj/lobby/input/gamepad/2.svg'),
	preload('res://obj/lobby/input/gamepad/3.svg'),
	preload('res://obj/lobby/input/gamepad/4.svg'),
	preload('res://obj/lobby/input/gamepad/5.svg'),
	preload('res://obj/lobby/input/gamepad/6.svg'),
	preload('res://obj/lobby/input/gamepad/7.svg'),
	preload('res://obj/lobby/input/gamepad/8.svg'),
	preload('res://obj/lobby/input/gamepad/9.svg'),
	preload('res://obj/lobby/input/gamepad/10.svg'),
	preload('res://obj/lobby/input/gamepad/11.svg'),
	preload('res://obj/lobby/input/gamepad/12.svg'),
	preload('res://obj/lobby/input/gamepad/13.svg'),
	preload('res://obj/lobby/input/gamepad/14.svg'),
	preload('res://obj/lobby/input/gamepad/15.svg')]

export(Array, String) var actions
export(Array, String) var labels

var number : String


func _ready():
	# Submenus assume that an InputMap is their parent, and that the
	# parent's setter-anchor contains a number.
	number = str($'..'.get_node($'..'.setter_anchor).number)
	# This is ugly, and I'd rather not make a habit of this.
	update_actions()


func update_actions():
	var j = 0
	for a in actions:
		var entry = get_child(j)
		entry.get_node('Keystroke').text = '--'
		entry.get_node('Gamepad').texture = null
		for e in InputMap.get_action_list(number + a):
			if e is InputEventKey:
				entry.get_node('Keystroke').text = e.as_text()
			elif e is InputEventJoypadButton:
				entry.get_node('Gamepad').texture \
					= GAMEPAD_TEXTURES[e.button_index]
		j += 1
