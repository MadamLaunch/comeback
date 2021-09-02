extends LobbySettingsItemSlider


export(NodePath) var master_node
var submenu

export(NodePath) var color_selector_node
var color_selector : LobbySettingsItem

export(String, 'R', 'G', 'B') var color = 'R'
export(String, 'block', 'ui') var starting_group = 'block'


func _ready():
	color_selector = get_node(color_selector_node)
	# The signal is applied programmatically to keep from needing to
	# make the ColorSlider node's children editable: this script is
	# meant to be slapped onto a LobbySettingItem_Slider, after all!
	# warning-ignore:return_value_discarded
	$Container/HSlider.connect('value_changed', self, 'update_color')


func update_color(slider_value):
	"""Update the Colors singleton's block-color and update the preview
	through the master node.
	
	Arguments:
	slider_value -- the new value from the child HSlider
	
	This method is called from the child HSlider's 'value_changed'
	signal during individual manipulation by a user.
	"""
	var index = color_selector.value
	var hex
	match starting_group:
		'block': hex = Color($'/root/Colors'.blocks[index])
		'ui': hex = Color($'/root/Colors'.ui[index])
	
	match color:
		'R': hex.r8 = slider_value
		'G': hex.g8 = slider_value
		'B': hex.b8 = slider_value
	
	match starting_group:
		# exclude alpha
		'block': $'/root/Colors'.blocks[index] = hex.to_html(false)
		'ui': $'/root/Colors'.ui[index] = hex.to_html(false)
	
	get_node(master_node).update_color(index)


func set_color(_number : int, _shift = 0, desync : bool = false):
	"""Disable internode signals and apply a preset.
	
	Arguments:
	_number -- ignored; included to allow this method to connect to
		a LobbySettingsItem's `setting_changed`-signal.
	_shift -- ignored; included to allow this method to connect to
		a LobbySettingsItem's `setting_changed`-signal.
	group -- a distinction for `sync_group`, either 'block' or
		'ui', to create '[group][R|G|B][color index]'
	
	This method is only ever called by the LobbySettingsItem in charge
	of color-presets.
	"""
	var m = get_node(master_node)
	
	# De-synchronize the slider to prevent another ColorSlider from
	# altering their value and overwriting the color's "custom"
	# preset.
	if desync:
		remove_from_group(sync_group)
		sync_group = ''
	
	# Pull the pertinent color-preset from the Colors singleton, using
	# the index from the master node, to apply to the child HSlider.
	var index = m.presets.value
	var hex
	match starting_group:
		'block': hex = $'/root/Colors'.block_presets[m.color][index].data
		'ui': hex = $'/root/Colors'.ui_presets[m.color][index].data
	
	# Temporarily disconnect the HSlider node from the ColorSlider to
	# prevent redundant calls to the master node and writes to the
	# global block-color value.
	$Container/HSlider.disconnect('value_changed', self, 'update_color')
	
	# Actually apply the value to the child HSlider.
	match color:
		'R': $Container/HSlider.value = hex.r8
		'G': $Container/HSlider.value = hex.g8
		'B': $Container/HSlider.value = hex.b8
	
	# Re-connect the child node to the color-updater for individual
	# manipulation.
	# warning-ignore:return_value_discarded
	$Container/HSlider.connect('value_changed', self, 'update_color')
	# Return to synchronization.
	if desync:
		sync_group = starting_group + color + str(m.color)
		add_to_group(sync_group)
