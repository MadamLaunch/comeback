extends ColorRect


const ButtonTheme = preload \
	('res://obj/lobby/presets/PresetDeleteWindowButton.theme')
const ButtonThemeHighlight = preload \
	('res://obj/lobby/presets/PresetDeleteWindowButton_highlighted.theme')

var number : String = ''
var menu_item
var read_input_directly = true


func _ready():
	set_process_input(false)


func launch(num, color, item):
	$'/root/InputOverride'.ignore_input = true
	$Anim.play('Fade In')
	
	number = num
	menu_item = item
	set_process_input(true)
	read_input_directly = true
	
	$Center/VBox/HBox/Confirm.number = num
	$Center/VBox/HBox/Cancel.number = num
	
	$Center/VBox/HBox/Confirm.release_focus()
	$Center/VBox/HBox/Cancel.release_focus()
	
	$Center/Outline.modulate = $'/root/Colors'.ui[color]
	
	var label = menu_item.values[menu_item.value]
	$Center/VBox/Label.text = 'P' + number + '\nDelete\n' + label + '?'


func _input(event : InputEvent):
	if not read_input_directly:
		return
	
	var close_window = false
	if event.is_action_pressed(number + '_confirm'):
		menu_item.delete_preset()
		close_window = true
	elif event.is_action_pressed(number + '_cancel'):
		close_window = true
	
	if close_window:
		close_window()
	else:
		if event.is_action_pressed(number + '_left'):
			activate_button(1)
		if event.is_action_pressed(number + '_right'):
			activate_button(2)


func close_window():
	call_deferred('_close_window')
	hide()
	
	set_process_input(false)
	$Center/VBox/HBox/Confirm.set_process_input(false)
	$Center/VBox/HBox/Cancel.set_process_input(false)


func _close_window():
	$'/root/InputOverride'.ignore_input = false


func activate_button(id : int = 0):
	var button : Button = null
	var other : Button = null
	match id:
		1:
			button = $Center/VBox/HBox/Confirm
			other = $Center/VBox/HBox/Cancel
		2:
			button = $Center/VBox/HBox/Cancel
			other = $Center/VBox/HBox/Confirm
		_:
			$Center/VBox/HBox/Confirm.theme = ButtonTheme
			$Center/VBox/HBox/Confirm.set_process_input(false)
			
			$Center/VBox/HBox/Cancel.theme = ButtonTheme
			$Center/VBox/HBox/Cancel.set_process_input(false)
			return
	
	read_input_directly = false
	
	button.theme = ButtonThemeHighlight
	button.set_process_input(true)
	
	other.theme = ButtonTheme
	other.set_process_input(false)
	other.release_focus()
