extends Control
class_name LobbySettingsSubMenu


export(NodePath) var master_node

var items : Array


func _ready():
	var _master = get_node(master_node)
	if not _master is Node:
		return
	
	var g = str(_master.get_instance_id())
	
	var previous #: LobbySettingsItem
	
	for child in get_children():
		if (not child is LobbySettingsItem
				&& not child.is_class('LobbySettingsItem')) \
				|| not child.visible:
			continue
		
		items.append(child)
		
		child.add_to_group(g)
		child.group = g
		
		if _master is LobbySettingsMenu:
			child.number = str(_master.number)
			
			var s = _master.get_node('Sprite')
			if s is Sprite:
				child.sprite = s
		
		if previous != null:
			previous.below = child
			child.above = previous
		
		previous = child


func play(animation):
	if has_node('Anim') \
			and $Anim is AnimationPlayer:
		$Anim.call_deferred('play', animation)


func _activate():
	for i in items:
		var signals = i.get_signal_connection_list('mouse_entered')
		if not signals.size():
			i.connect('mouse_entered', i, 'activate')


func _deactivate():
	for i in items:
		var signals = i.get_signal_connection_list('mouse_entered')
		if signals.size():
			i.disconnect('mouse_entered', i, 'activate')
