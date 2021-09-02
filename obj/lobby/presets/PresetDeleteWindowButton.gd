extends Button

export(NodePath) var window
export var delete = false
var number : String


func _ready():
	set_process_input(false)


func _input(event : InputEvent):
	if event.is_action_pressed(number + '_left') \
			or event.is_action_pressed(number + '_right'):
		get_node(focus_next).grab_focus()
	elif event.is_action_pressed(number + '_confirm'):
		click()
	elif event.is_action_pressed(number + '_cancel'):
		get_node(window).close_window()


func click():
	var w = get_node(window)
	if delete:
		w.delete_preset()
	w.close_window()
