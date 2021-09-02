extends Control
class_name LobbySettingsMenu


# warning-ignore:unused_class_variable
export(int, 1, 4) var number = 1
export(int, 0, 7) var color = 0
export(Array, Texture) var sprites

export(NodePath) var number_node
export(NodePath) var color_node
export(NodePath) var starting_node

export(NodePath) var gameplay_settings_node

var _n : String

var ready : bool
var settings : GameplaySettings

var saved_item : LobbySettingsItem


signal launch()
signal reorder(caller, new_position, shift)


func _ready():
	_n = str(number)
	
	get_node(number_node).set_value(number - 1)
	
	# Remove background from default group and assign true value.
	$Background.remove_from_group('Background0')
	set_color(color)
	get_node(color_node).set_value(color)
	
	# Disable menu items and quit/ready checks if hidden.
	if not visible:
		get_node(starting_node).deactivate()
		set_process_input(false)
	else:
		get_node(starting_node).activate()


func set_color(new_color, shift = 0):
	"""Change the background color to a different indexed value.
	
	Arguments:
	new_color -- which stored UI color to assign
	shift -- which direction the active menu item moved; 1 or -1
		(default: 0)
	
	If `shift` is not 0, then remove the background from whichever
	group it must have been previously added to. `shift` will be 0 when
	the LobbySettingMenu initializes itself via `_ready()`.
	"""
	if shift:
		$Background.remove_from_group('Background' + str(color))
	$Background.color = $'/root/Colors'.ui[new_color]
	$Background.add_to_group('Background' + str(new_color))
	
	$Sprite.texture = sprites[new_color]
	
	color = new_color


func set_ready(caller, is_ready : bool):
	"""Set whether or not the overlay (true) or the menu items
	(false) are active.
	
	Arguments:
	caller -- which LobbySettingItem was active and readying
	is_ready -- whether or not the menu will be ready
	"""
	var tree = get_tree()
	# Deactivate all the contained menu items and raise the overlay.
	if is_ready:
		# Prevent _input() from reading the confirm-signal.
		set_deferred('ready', is_ready)
		
		if caller is LobbySettingsItem:
			saved_item = caller
		
		# Save the gameplay settings currently live within the menu.
		settings = get_node(gameplay_settings_node).package_settings()
		
		# Set it so only the overlay can respond to input.
		var g = str(get_instance_id())
		tree.call_group(g, 'deactivate')
		tree.call_group(g + ' instruction', 'hide')
		$Overlay.show()
		$Overlay/Button.disabled = false
	# Lower the overlay and re-activate the last active menu item.
	else:
		# Shut down input-processing immediately.
		ready = false
		
		if saved_item is LobbySettingsItem:
			saved_item.activate()
		
		# Free the settings data object to memory.
		if settings:
			settings.free()
			settings = null
		
		# Lower the overlay.
		$Overlay.hide()
		$Overlay/Button.disabled = true


func _input(event : InputEvent):
	if $'/root/InputOverride'.ignore_input:
		return
	
	if event.is_action_pressed('quit'):
		get_tree().quit()
	
	if ready:
		if event.is_action_pressed(_n + '_cancel'):
			set_ready(null, false)
		elif event.is_action_pressed(_n + '_confirm'):
			emit_signal('launch')
			$Overlay/Button.disabled = true


func emit_reorder(new_position, shift):
	"""Signal to LobbySettings to re-order the menus it contains.
	
	Arguments:
	new_position -- where the menu node is now ordered
	shift -- which direction the menu moved in
	"""
	emit_signal('reorder', self, new_position, shift)


func set_order(new_position):
	"""Assign the x-position to the menu's number node;
	position the menu node accordingly.
	
	Arguments:
	new_position -- the new x-position of the menu; usually 0 to 3
	"""
	get_node(number_node).value = new_position
	rect_position.x = rect_size.x * new_position


func order():
	"""Return the value stored within the menu's number node for
	LobbySettings."""
	return get_node(number_node).value
