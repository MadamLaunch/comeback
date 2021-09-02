extends Node2D
class_name PatternSelector


export var number = '1'
export(NodePath) var opponent_container
export(NodePath) var opponent_selector
export(NodePath) var parent_animator

var container : BlockContainer
var opponent : PatternSelector
var animator : AnimationPlayer

export(Vector2) var docked_position
export(Vector2) var docked_scale = Vector2.ONE
export(Vector2) var raised_position
export(Vector2) var raised_scale = Vector2.ONE

var pattern = [0, 0]
var row : int = 0

export var ready = false


func _ready():
	for j in range(7):
		var c = str(j)
		for block in get_tree().get_nodes_in_group('block' + c):
			block.modulate = $'/root/Colors'.blocks[j]
	
	container = get_node(opponent_container)
	opponent = get_node(opponent_selector)
	animator = get_node(parent_animator)
	
	var anim = AnimationPlayer.new()
	anim.name = 'Anim'
	add_child(anim)
	
	anim.add_animation('Dock', Animation.new())
	anim.add_animation('Raise', Animation.new())
	
	var anims = [anim.get_animation('Dock'), anim.get_animation('Raise')]
	var pos = \
		[[raised_position, docked_position], [docked_position, raised_position]]
	var _scale = [[raised_scale, docked_scale], [docked_scale, raised_scale]]
	
	for j in range(2):
		anims[j].length = .35
		var f = anims[j].add_track(Animation.TYPE_METHOD)
		anims[j].track_set_path(f, '.')
		anims[j].track_insert_key(f, 0, {'method': 'deactivate' , 'args' : []})
		var r = anims[j].add_track(Animation.TYPE_VALUE)
		anims[j].track_set_path(r, '.:ready')
		anims[j].track_insert_key(r, 0, false)
		var b = anims[j].add_track(Animation.TYPE_VALUE)
		anims[j].track_set_path(b, 'Ready:disabled')
		anims[j].track_insert_key(b, 0, true)
		anims[j].track_insert_key(b, .35, false)
		var p = anims[j].add_track(Animation.TYPE_VALUE)
		anims[j].track_set_path(p, '.:position')
		anims[j].track_insert_key(p, 0, pos[j][0])
		anims[j].track_insert_key(p, .35, pos[j][1])
		anims[j].track_set_key_transition(p, 0, .3)
		var s = anims[j].add_track(Animation.TYPE_VALUE)
		anims[j].track_set_path(s, '.:scale')
		anims[j].track_insert_key(s, 0, _scale[j][0])
		anims[j].track_insert_key(s, .35, _scale[j][1])
		anims[j].track_set_key_transition(s, 0, .3)
	
	var raise_anim = anim.get_animation('Raise')
	var f = raise_anim.find_track('.')
	raise_anim.track_insert_key(f, .35, {'method': 'activate' , 'args' : []})


func dock(): $Anim.play('Dock')


func raise(): $Anim.play('Raise')


func disable_ready():
	$Ready.disabled = true
	set_process_input(false)


func toggle_ready(override=null):
	if override != null:
		if not override:
			animator.play('Ready')
		else:
			animator.play('Unready')
	else:
		if not ready:
			animator.play('Ready')
		else:
			animator.play('Unready')


func start_game():
	container.GARBAGE_PATTERN = PATTERNS[row][pattern[row]]
	
	if not opponent.ready: return
	
	animator.play('Start')
	opponent.animator.play('Start')


func _input(event : InputEvent):
	if event.is_action_pressed(number + '_confirm'):
		toggle_ready(false)
	if event.is_action_pressed(number + '_cancel'):
		toggle_ready(true)
	
	if ready: return
	
	if event.is_action_pressed(number + '_left'):
		$L.emit_signal('pressed')
	if event.is_action_pressed(number + '_right'):
		$R.emit_signal('pressed')
	if event.is_action_pressed(number + '_up'):
		$U.emit_signal('pressed')
	if event.is_action_pressed(number + '_down'):
		$D.emit_signal('pressed')


func shift_pattern(direction : int):
	var r = get_node('Row' + str(row))
	var p = pattern[row]
	
	r.get_node('Pattern' + str(p)).hide()
	
	p += direction
	if p < 0:
		p = r.get_child_count() - 1
	elif p >= r.get_child_count():
		p = 0
	
	r.get_node('Pattern' + str(p)).show()
	pattern[row] = p


func shift_row():
	get_node('Row' + str(row)).hide()
	
	if row == 1:
		row = 0
	else:
		row = 1
	
	get_node('Row' + str(row)).show()


func activate():
	for button in [$L, $R, $U, $D]:
		button.disabled = false
		button.show()
		
		button.get_node('Anim1').seek(0, true)
	
	set_process_input(true)


func deactivate():
	for button in [$L, $R, $U, $D]:
		button.disabled = true
		button.hide()


const PATTERNS = [
	[
		# Bars
		[[0, 0, 0, 0, 0, 0, 0],
		 [3, 3, 3, 3, 3, 3, 3],
		 [1, 1, 1, 1, 1, 1, 1],
		 [2, 2, 2, 2, 2, 2, 2]],
		# Rushdown
		[[2, 3, 0, 1, 2, 3, 0],
		 [4, 4, 4, 4, 4, 4, 4],
		 [4, 4, 4, 4, 4, 4, 4],
		 [4, 4, 4, 4, 4, 4, 4]],
		# Blocks
		[[2, 2, 4, 4, 0, 0, 3],
		 [2, 2, 4, 4, 0, 0, 3],
		 [0, 3, 3, 1, 1, 2, 2],
		 [0, 3, 3, 1, 1, 2, 2]],
		# Slanted Rainbow w/ Walls
		[[4, 1, 3, 0, 2, 1, 4],
		 [4, 2, 1, 3, 0, 2, 4],
		 [4, 0, 2, 1, 3, 0, 4],
		 [4, 3, 0, 2, 1, 3, 4]],
		# FREEDOM
		[[2, 2, 2, 2, 2, 2, 2],
		 [1, 1, 1, 1, 1, 1, 1],
		 [4, 0, 4, 2, 2, 2, 2],
		 [0, 4, 0, 1, 1, 1, 1]]
	],
	[
		# Blue (Water)
		[[0, 0, 0, 0, 0, 0, 0]],
		# Yellow (Electricity)
		[[1, 1, 1, 1, 1, 1, 1]],
		# Red (Fire)
		[[2, 2, 2, 2, 2, 2, 2]],
		# Green (Earth)
		[[3, 3, 3, 3, 3, 3, 3]],
		# Pink/Purple (Sprit)
		[[4, 4, 4, 4, 4, 4, 4]],
		# Black (Death)
		[[5, 5, 5, 5, 5, 5, 5]],
		# White (Life)
		[[6, 6, 6, 6, 6, 6, 6]]
	]
]
