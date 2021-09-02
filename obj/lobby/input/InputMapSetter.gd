extends Control


var caller : Control
var number : String

var submenu
var actions : Array
var labels : Array

var entry = 0


func _ready():
	$CenterContainer/Label.text = labels[entry]


func _input(event : InputEvent):
	if $'/root/InputOverride'.ignore_input:
		return
	
	if not (event is InputEventKey or event is InputEventJoypadButton) \
			or not event.is_pressed():
		return
	
	var action = number + actions[entry]
	for e in InputMap.get_action_list(action):
		if e.get_class() == event.get_class():
			InputMap.action_erase_event(action, e)
	
	InputMap.action_add_event(action, event)
	
	entry += 1
	if entry >= actions.size() \
			or entry >= labels.size():
		submenu.update_actions()
		$'/root/Controls'.save()
		
		caller.activate()
		queue_free()
	else:
		$CenterContainer/Label.text = labels[entry]
