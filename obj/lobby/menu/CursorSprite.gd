extends Sprite


var item = null


# warning-ignore:unused_argument
func _process(delta):
	if not item is Control:
		return
	
	var parent
	if item is LobbySettingsSubMenuSelector:
		parent = item.get_node('..')
	else:
		parent = item.get_node('../..')
	if not parent is Control:
		item = null
		return
	
	position.x \
		= parent.rect_position.x \
		+ item.rect_position.x \
		+ 80
	position.y \
		= parent.rect_position.y \
		+ item.rect_position.y \
		+ (item.rect_size.y / 2)
