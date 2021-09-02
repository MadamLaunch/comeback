extends Block
class_name Shelf


var length = 3


func get_class():
	return 'Shelf'


func is_class(type):
	return type == 'Shelf' or .is_class(type)


func _ready():
	set_process(false)


func key():
	"""Produce a list of the points the Shelf occupies."""
	var p = point()
	var k = []
	var y = ',' + str(p.y)
	for x in range(length):
		k.append(str(p.x + x) + y)
	return k


func set_length(L):
	"""Set the dimensions of $Body and $Flash, position symbol."""
	length = L
	$Body.rect_size.x = SIZE * length
	$Flash.rect_size.x = SIZE * length
	#warning-ignore:integer_division
	$Body/Symbol.position.x = ($Body.rect_size.x / 2) - (SIZE / 2)


func set_color(index, _ignore = null):
	"""Set the modulation and symbol for Shelfs.
	
	Arguments:
	index -- the entry in the Colors singleton to get values from
	_ignore -- simply here for the `setting_changed` signal emitted
		by LobbySettingsItem
	"""
	var C = get_node('/root/Colors')
	
	color = index
	$Body.modulate = Color(C.blocks[index])
	$Body/Symbol.frame = C.frames[index]


# warning-ignore:unused_argument
func settle(grid=null, instant=false):
	"""Drop the Shelf to the lowest immediate empty spot possible.
	
	Arguments:
	grid -- the BlockContainer that should be examined (default: null)
	instant -- whether or not move the piece in one step (default: false)
		(ignored by Shelf)
	
	Each column in the row immediately below the Shelf is checked to
	see if it is empty: if they all are; enable per-frame processing,
	which will repeat this check and lower the Shelf once every frame
	until any column returns as being occupied.
	
	The Shelf's parent is used for a grid if none is supplied as an
	argument; used in `descend()` on partnered blocks.
	"""
	if not grid:
		grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	var p = point()
	var cleared = true
	for x in range(length):
		var px = p.x + x
		if grid.collision(px, p.y + 1):
			cleared = false
			break
	
	if cleared:
		set_process(true)
		tally_settlement()
		return true


# warning-ignore:unused_argument
func _process(delta):
	"""Move down one row if every column below is empty; start next
	turn if this the last game-piece to settle.
	
	Arguments:
	delta -- the amount of time that has passed since the last frame
		(ignored by Shelf)
	"""
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	var p = point()
	var cleared = true
	for x in range(length):
		var px = p.x + x
		if grid.collision(px, p.y + 1):
			cleared = false
			set_process(false)
			break
	
	if cleared:
		grid.remove(self)
		move(0, 1)
		grid.add(self)
		
		for x in range(length):
			for y in range(p.y - 1, -3, -1):
				var next = grid.collision(p.x + x, y)
				if next:
					next.settle()
					break
		
		tally_settlement(false)
		if grid.settling_pieces.size() == 0:
			next_turn()


func detonate():
	"""Trigger explosions in any adjacent pieces of the same color."""
	var p = point()
	var s = []
	for l in range(length):
		s.append([p.x + l, p.y - 1])
		s.append([p.x + l, p.y + 1])
	
	for P in s:
		var g = $'..'.collision(P[0], P[1])
		# Do nothing in the case of an empty point or wall.
		if typeof(g) == TYPE_BOOL:
			continue
		if g.color == color and not g.is_garbage:
			if not exploding:
				explode()
			
			exploding = true
			
			g.get_node('Anim').play('Explode')
	if exploding:
		for P in s:
			var g = $'..'.collision(P[0], P[1])
			# Do nothing in the case of an empty point or wall.
			if typeof(g) == TYPE_BOOL:
				continue
			if g.is_garbage:
				g.get_node('Anim').play('Explode')
		return 1
	else:
		return 0


const ShelfExplosion \
	= preload('res://obj/gameplay/block/shelf/ShelfExplosion_GLES2.tscn')


func explode(apply_bonus=true):
	"""Spawn an explosion object and remove self from gameplay."""
	# Remove garbage/add to offensive payload.
	if apply_bonus:
		$'..'.remove_garbage(length * 2, true)
	else:
		$'..'.remove_garbage(length)
	
	var p = point()
	var pitch = rand_range(.6, .8)
	for l in range(length):
		$'..'.blocks.erase(str(p.x + l) + ',' + str(p.y))
	
		var e = ShelfExplosion.instance()
		e.position = position + Vector2(l * SIZE, 0)
		if l:
			e.get_node('Audio').volume_db = -80
		else:
			e.get_node('Audio').pitch_scale = pitch
			e.get_node('Audio').volume_db = 1.5 * length
		if $'..'.explosion_layer:
			$'..'.explosion_layer.add_child(e)
		else:
			$'..'.add_child(e)
		$'..'.play('Re-settle')
	
	queue_free()
