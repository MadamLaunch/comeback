extends VBoxContainer
class_name LobbySettingsItem


const Highlight = preload('res://obj/lobby/item/LobbySettingsItem_highlighted.theme')

const Number = preload('res://obj/lobby/item/NumberFont.tres')
const NumberHighlight = preload('res://obj/lobby/item/NumberFont_highlighted.tres')

const Prompt = preload('res://obj/lobby/item/LobbySettingsItem_Prompt.theme')
const PromptHighlight = preload('res://obj/lobby/item/LobbySettingsItem_Prompt_highlighted.theme')

const L = preload('res://obj/lobby/item/triangle_l.svg')
const LHighlight = preload('res://obj/lobby/item/triangle_l_highlight.svg')

const R = preload('res://obj/lobby/item/triangle_r.svg')
const RHighlight = preload('res://obj/lobby/item/triangle_r_highlight.svg')

export var active = false
export var large_value = false
export(String) var label
export(Array, String) var values
export var disable_button = false
export(String) var suffix
export var static_value = false
export var retain_arrows = false
export(int, 0, 100) var starting_value
export(String) var prompt
export(Array, String) var prompts
export(String) var instruction
export(Array, String) var instructions

var above #: LobbySettingsItem
var below #: LobbySettingsItem

var group : String
var number : String
var sprite : Sprite
var value : int


signal activated(caller)
signal deactivated(caller)
signal setting_changed(number, shift)
signal up(parent)
signal down(parent)
signal confirm(caller)
signal cancel()


func _ready():
	if label:
		$Label.text = label
	else:
		$Label.hide()
	
	if starting_value < values.size():
		value = starting_value
		_set_value(true, 0, false)
	
	$Prompt.show()
	if prompt:
		$Prompt.text = prompt
	elif prompts.size():
		var p = value
		if p > prompts.size():
			p = prompts.size() - 1
		$Prompt.text = prompts[p]
	else:
		$Prompt.hide()
	
	if retain_arrows:
		for _sprite in [$Value/L/SpriteAnchor, $Value/R/SpriteAnchor]:
			_sprite.show()
			_sprite.modulate = Color(0, 0, 0, .27)
	else:
		$Value/L/SpriteAnchor.hide()
		$Value/R/SpriteAnchor.hide()
	
	if disable_button:
		$Value/Button.disabled = true
	
	if active:
		#call_deferred('activate')
		#activate()
		pass
	else:
		#deactivate(null)
		pass


func _arrange_buttons():
	for button in [$Value/L, $Value/R]:
		var anchor = button.get_node('SpriteAnchor')
		match button.name:
			'L':
				anchor.position.x = button.rect_size.x - 10
			'R':
				anchor.position.x = 10
		anchor.position.y = button.rect_size.y * .5


func activate():
	get_tree().call_group(group, 'deactivate', self)
	
	theme = Highlight
	$Prompt.modulate.a = 1
	
	set_process_input(true)
	emit_signal('activated', self)
	
	if sprite:
		sprite.call_deferred('show')
		sprite.item = self
	
	if large_value:
		$Value/Text.add_font_override('font', NumberHighlight)
		$Value/Button.add_font_override('font', NumberHighlight)
	
	if $Prompt.visible:
		$Prompt.theme = PromptHighlight
	
	if prompts.size():
		var p = value
		if p >= prompts.size():
			p = prompts.size() - 1
		$Prompt.text = prompts[p]
	
	if instruction:
		get_tree().call_group(
			group + ' instruction',
			'display',
			instruction)
	elif instructions.size():
		get_tree().call_group(
			group + ' instruction',
			'display',
			instructions[value])
	else:
		get_tree().call_group(
			group + ' instruction',
			'hide')
	
	if values.size() > 1:
		for button in [$Value/L, $Value/R]:
			button.disabled = false
			var anchor = button.get_node('SpriteAnchor')
			anchor.show()
			anchor.set_process(true)
			anchor.modulate = Color.white
			anchor.get_node('Sprite/Anim1').play('Wave')
			if button.name == 'L':
				anchor.get_node('Sprite').texture = LHighlight
			else:
				anchor.get_node('Sprite').texture = RHighlight
	
	active = true


func deactivate(activated = null):
	if activated == self:
		return
	
	theme = null
	$Prompt.modulate.a = 0
	
	set_process_input(false)
	emit_signal('deactivated', self)
	
	if sprite:
		sprite.hide()
	
	if large_value:
		$Value/Text.add_font_override('font', Number)
		$Value/Button.add_font_override('font', Number)
	
	if $Prompt.visible:
		$Prompt.theme = Prompt
	
	for button in [$Value/L, $Value/R]:
		button.disabled = true
		var _sprite = button.get_node('SpriteAnchor')
		_sprite.get_node('Sprite/Anim1').stop()
		if retain_arrows:
			_sprite.get_node('Sprite').offset = Vector2.ZERO
			_sprite.modulate = Color(0, 0, 0, .27)
		else:
			_sprite.hide()
		if button.name == 'L':
			_sprite.get_node('Sprite').texture = L
		else:
			_sprite.get_node('Sprite').texture = R
	
	active = false


func hibernate():
	set_process_input(false)


func awaken():
	if active:
		set_process_input(true)


func set_value(v, signal_change = false):
	if v < 0:
		v = values.size() - 1
	elif v >= values.size():
		v = 0
	
	value = v
	$Value/Text.text = values[v] + suffix
	$Value/Button.text \
		= str(values[v] + suffix).to_upper()
	
	if prompts.size():
		var p = value
		if p >= prompts.size():
			p = prompts.size() - 1
		
		$Prompt.text = prompts[p]
	
	if signal_change:
		emit_signal('setting_changed', value, 0)


func change_signal_override(_number, _shift, v):
	set_value(v, true)


func _set_value(static_override : bool, shift : int, signal_change = true):
	if value < values.size():
		var v = values[value]
		
		if not static_value or static_override:
			$Value/Text.text = v + suffix
			$Value/Button.text = str(v + suffix).to_upper()
		
		if signal_change:
			emit_signal('setting_changed', value, shift)
		
		if shift == -1:
			$Value/L/SpriteAnchor/Sprite/Anim2.stop()
			$Value/L/SpriteAnchor/Sprite/Anim2.play('Pulse')
		elif shift == 1:
			$Value/R/SpriteAnchor/Sprite/Anim2.stop()
			$Value/R/SpriteAnchor/Sprite/Anim2.play('Pulse')
	
	if prompts.size():
		var p = value
		if p >= prompts.size():
			p = prompts.size() - 1
		
		$Prompt.text = prompts[p]
	
	if instructions.size():
		var i = value
		if i >= instructions.size():
			i = instructions.size() - 1
		
		get_tree().call_group(
			group + ' instruction',
			'display',
			instructions[i])


func shift_value(direction):
	value += direction
	var size = values.size()
	if value < 0:
		value = size - 1
	elif value >= size:
		if direction < 0:
			value = size - 1
		elif direction > 0:
			value = 0
	
	_set_value(false, direction)
	accept_event()


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
	
	var lateral = 0
	if event.is_action_pressed(number + '_left'):
		lateral -= 1
	if event.is_action_pressed(number + '_right'):
		lateral += 1
	
	if lateral:
		value += lateral
		var size = values.size()
		if value < 0:
			value = size - 1
		elif value >= size:
			value = 0
		
		_set_value(false, lateral)
	
	if event.is_action_pressed(number + '_confirm'):
		emit_signal('confirm', self)
	elif event.is_action_pressed(number + '_cancel'):
		emit_signal('cancel')


func confirm():
	emit_signal('confirm', self)
