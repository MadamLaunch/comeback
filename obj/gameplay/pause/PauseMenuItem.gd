extends Button
class_name PauseMenuItem


var above : Button = null
var below : Button = null

var number : String


func _ready():
	$Icon.position.x = (rect_size.x / 2) - 100
	set_process_input(false)


func activate():
	add_color_override('font_color', Color.white)
	$Anim.play('Wave')
	$Icon.show()
	set_process_input(true)
	
	get_tree().call_group('PauseMenuItem', 'deactivate', self)


func deactivate(activated = null):
	if activated == self:
		return
	
	add_color_override('font_color', Color('#777'))
	$Anim.stop()
	$Icon.hide()
	set_process_input(false)
	release_focus()


func assign_number(n : String):
	number = n


func _input(event : InputEvent):
	if not event.is_action_type():
		return
	
	if event.is_action_pressed(number + '_up'):
		above.activate()
	if event.is_action_pressed(number + '_down'):
		below.activate()
	if event.is_action_pressed(number + '_confirm'):
		emit_signal('pressed')
