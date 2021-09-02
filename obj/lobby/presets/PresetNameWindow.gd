extends ColorRect


var number : String = ''
var menu_item


func _ready():
	set_process_input(false)


func launch(num, color, item):
	$'/root/InputOverride'.ignore_input = true
	$Anim.play('Fade In')
	
	number = num
	menu_item = item
	set_process_input(true)
	
	$Center/Outline.modulate = $'/root/Colors'.ui[color]
	$Center/VBox/Line.modulate = $Center/Outline.modulate
	
	$Center/VBox/Label.text \
		= 'P' + number + '\nSave Preset'
	
	$Center/VBox/TextEdit.text = ''
	$Center/VBox/TextEdit.grab_focus()


func _uppercase():
	var column = $Center/VBox/TextEdit.cursor_get_column()
	$Center/VBox/TextEdit.text = $Center/VBox/TextEdit.text.to_upper()
	$Center/VBox/TextEdit.cursor_set_column(column)


func _input(event : InputEvent):
	var close_window = false
	if event.is_action_pressed(number + '_cancel'):
		if event is InputEventKey \
				and (event.scancode == KEY_BACKSPACE
				or event.scancode == KEY_DELETE):
			if $Center/VBox/TextEdit.text.length() > 0:
				return
		close_window = true
	elif event.is_action_pressed(number + '_confirm'):
		menu_item.save_preset($Center/VBox/TextEdit.text)
		close_window = true
	
	if close_window:
		close_window()

func close_window():
	call_deferred('_close_window')
	hide()
	
	number = ''
	set_process_input(false)

func _close_window():
	$'/root/InputOverride'.ignore_input = false
