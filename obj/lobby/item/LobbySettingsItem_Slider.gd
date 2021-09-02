extends VBoxContainer
class_name LobbySettingsItemSlider


export var active = false
export(String) var label
export(String) var sync_group
export(int) var label_multiplier = 1

var above #: LobbySettingsItem
var below #: LobbySettingsItem

var group : String
var number : String
var sprite : Sprite

export(Array, String) var constant_signals


signal activated(caller)
signal deactivated(caller)
signal setting_changed(number, shift)
signal up(parent)
signal down(parent)
signal confirm(caller)
signal cancel()


func get_class():
	return 'LobbySettingsItem'


func is_class(type):
	return type == 'LobbySettingsItem' or .is_class(type)


func _ready():
	if label:
		$Label.text = label
	else:
		$Label.hide()
	
	$Container/L/SpriteAnchor.position.x = 40
	$Container/L/SpriteAnchor.position.y = 22
	
	$Container/R/SpriteAnchor.position.x = 20
	$Container/R/SpriteAnchor.position.y = 22


func activate():
	get_tree().call_group(group, 'deactivate', self)
	
	theme = LobbySettingsItem.Highlight
	
	set_process(true)
	set_process_input(true)
	emit_signal('activated', self)
	
	if sprite:
		sprite.call_deferred('show')
		sprite.item = self
	
	$Container/HSlider.modulate = Color.white
	
	for button in [$Container/L, $Container/R]:
		button.disabled = false
	
	for anchor in \
			[$Container/L/SpriteAnchor, $Container/R/SpriteAnchor]:
		anchor.show()
		anchor.modulate = Color.white
		anchor.get_node('Sprite/Anim1').play('Wave')
		if anchor.get_node('..').name == 'L':
			anchor.get_node('Sprite').texture = LobbySettingsItem.LHighlight
		else:
			anchor.get_node('Sprite').texture = LobbySettingsItem.RHighlight
	
	$Value.theme = LobbySettingsItem.PromptHighlight
	
	active = true


func deactivate(activated = null):
	if activated == self:
		return
	
	theme = null
	
	set_process(false)
	set_process_input(false)
	emit_signal('deactivated', self)
	
	if sprite:
		sprite.hide()
	
	$Container/HSlider.modulate = Color(0, 0, 0, .27)
	
	for button in [$Container/L, $Container/R]:
		button.disabled = true
	
	for anchor in \
			[$Container/L/SpriteAnchor, $Container/R/SpriteAnchor]:
		anchor.modulate = Color(0, 0, 0, .27)
		anchor.get_node('Sprite/Anim1').stop()
		anchor.get_node('Sprite').offset = Vector2.ZERO
		if anchor.get_node('..').name == 'L':
			anchor.get_node('Sprite').texture = LobbySettingsItem.L
		else:
			anchor.get_node('Sprite').texture = LobbySettingsItem.R
	
	$Value.theme = LobbySettingsItem.Prompt
	
	active = false


func hibernate():
	set_process(false)
	set_process_input(false)


func awaken():
	if active:
		set_process(true)
		set_process_input(true)


func disable_connections(list : Array, retain_constants : bool):
	for c in list:
		if retain_constants and constant_signals.has(c.method):
			continue
		
		$Container/HSlider.disconnect('value_changed', c.target, c.method)


func restore_connections(list : Array):
	for c in list:
		if not constant_signals.has(c.method):
			# warning-ignore:return_value_discarded
			$Container/HSlider.connect('value_changed', c.target, c.method)


func set_value(v, signal_change = false, disable_sync = false):
	var connections
	if disable_sync:
		connections = \
			$Container/HSlider.get_signal_connection_list('value_changed')
		disable_connections(connections, true)
	
	$Container/HSlider.value = v
	$Value.text = str(int(v * label_multiplier))
	
	if disable_sync:
		restore_connections(connections)
	
	if signal_change:
		emit_signal('setting_changed', v, 0)


func shift_value(direction : int):
	var b : String
	if direction == -1:
		b = 'L'
	elif direction == 1:
		b = 'R'
	else:
		return
	
	get_node('Container/' + b + '/SpriteAnchor/Sprite/Anim2').stop()
	get_node('Container/' + b + '/SpriteAnchor/Sprite/Anim2').play('Pulse')
	
	$Container/HSlider.value += $Container/HSlider.step * direction


func _input(event : InputEvent):
	if $'/root/InputOverride'.ignore_input:
		return
	
	if event.is_action_pressed(number + '_up'):
		if above:
			above.activate()
		emit_signal('up', $'..')
	if event.is_action_pressed(number + '_down'):
		if below:
			below.activate()
		emit_signal('down', $'..')
	
	var lateral : float = 0
	if event.is_action_pressed(number + '_left', true):
		lateral -= 1
		$Container/L/SpriteAnchor/Sprite/Anim2.stop()
		$Container/L/SpriteAnchor/Sprite/Anim2.play('Pulse')
	if event.is_action_pressed(number + '_right', true):
		lateral += 1
		$Container/R/SpriteAnchor/Sprite/Anim2.stop()
		$Container/R/SpriteAnchor/Sprite/Anim2.play('Pulse')
	
	if lateral:
		$Container/HSlider.value += $Container/HSlider.step * lateral
	
	if event.is_action_pressed(number + '_confirm'):
		emit_signal('confirm', self)
	elif event.is_action_pressed(number + '_cancel'):
		emit_signal('cancel')


func _synchronize(value):
	if sync_group:
		get_tree().call_group(sync_group, 'set_value', value, true, true)
	else:
		set_value(value, true)


func _save_volume(value):
	AudioServer.set_bus_volume_db \
		($'/root/Settings'.get(sync_group), linear2db(value))
	$'/root/Settings'.save_volume()
