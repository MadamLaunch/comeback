extends LobbySettingsItem
class_name LobbySettingsSubMenuSelector

export(Array, NodePath) var submenus

var current_submenu : int = 0


func _ready():
	change_submenu(starting_value, 0, false)


func change_submenu(number, shift, animate = true):
	"""
	
	Arguments:
	number --
	shift --
	animate --
	
	
	"""
	var old_menu = get_node(submenus[current_submenu])
	var new_menu = get_node(submenus[number])
	
	if animate:
		var amendment
		if shift == -1:
			amendment = ' (Right)'
		else:
			amendment = ' (Left)'
		
		old_menu.play('Slide Out' + amendment)
		new_menu.play('Slide In' + amendment)
	
	current_submenu = number
	
	var first = true
	var final #: LobbySettingsItem
	
	for c in new_menu.get_children():
		if not c is LobbySettingsItem \
				and not c.is_class('LobbySettingsItem'):
			continue
		
		if first:
			c.above = self
			below = c
			first = false
		
		final = c
	
	if final:
		above = final
		final.below = self
