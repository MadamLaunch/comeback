extends PanelContainer


const Inactive = preload('res://obj/lobby/input/InputMap.theme')
const Highlight = preload('res://obj/lobby/input/InputMap_highlighted.theme')

const Setter = preload('res://obj/lobby/input/InputMapSetter.tscn')

export(NodePath) var setter_anchor
export(NodePath) var rotation_node

var submenus : Array
var current_submenu = 0


func _ready():
	submenus = [
		$Rotation1,
		$Movement,
		$DropCursor,
		$Pausing,
		$Menus]
	
	var rotation = get_node(rotation_node)
	var n = $'..'.get_node($'..'.master_node).number - 1
	
	rotation.set_value($'/root/Controls'.relative_rotation[n], true)


func activate(_caller):
	theme = Highlight


func deactivate(_caller):
	theme = Inactive


# warning-ignore:unused_argument
func cycle_submap(number, shift):
	if not submenus.size():
		return
	
	submenus[current_submenu].modulate.a = 0
	
	current_submenu += shift
	if current_submenu < 0:
		current_submenu = submenus.size() - 1
	elif current_submenu >= submenus.size():
		current_submenu = 0
	
	submenus[current_submenu].modulate.a = 1


func set_rotation_mode(number, _shift):
	if not submenus.size():
		return
	
	if current_submenu == 0:
		submenus[0].modulate.a = 0
		
	var n = $'..'.get_node($'..'.master_node).number - 1
	if number == 0:
		submenus[0] = $Rotation1
		$'/root/Controls'.relative_rotation[n] = 0
	elif number == 1:
		submenus[0] = $Rotation2
		$'/root/Controls'.relative_rotation[n] = 1
	
	if current_submenu == 0:
		submenus[0].modulate.a = 1
	
	$'/root/Controls'.save()


func launch_input_setter(caller):
	caller.deactivate()
	
	var setter = Setter.instance()
	setter.caller = caller
	setter.number = caller.number
	
	var submenu = submenus[current_submenu]
	setter.submenu = submenu
	setter.actions = submenu.actions
	setter.labels = submenu.labels
	
	get_node(setter_anchor).add_child(setter)


func execute_task(caller):
	var actions = submenus[current_submenu].actions
	
	var keystroke \
		= caller.value == 0 or caller.value == 1 \
		or caller.value == 3 or caller.value == 4
	var gamepad \
		= caller.value == 0 or caller.value == 2 \
		or caller.value == 3 or caller.value == 5
	
	for a in actions:
		var action = caller.number + a
		
		# Clear the submenu's inputs.
		for e in InputMap.get_action_list(action):
			if (keystroke and e is InputEventKey) \
					or (gamepad and e is InputEventJoypadButton):
				InputMap.action_erase_event(action, e)
		
		# Reset the submenu's inputs.
		if caller.value < 3:
			for e in $'/root/Controls'.default_controls[action]:
				if (keystroke and e is InputEventKey) \
						or (gamepad and e is InputEventJoypadButton):
					InputMap.action_add_event(action, e)
	
	submenus[current_submenu].update_actions()
	$'/root/Controls'.save()
