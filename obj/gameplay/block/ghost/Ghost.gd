extends 'res://obj/gameplay/GridObject.gd'
class_name Ghost


const Block = preload('res://obj/gameplay/block/Block.tscn')
const Garbage = preload('res://obj/gameplay/block/garbage/Garbage.tscn')

export(int, 0, 6) var color
#warning-ignore:unused_class_variable
export var persistent = false
# `persistent` is used within BlockContainer to retain the Ghosts for
# falling Blocks.
export var partner = false
export var do_not_restart = false


func get_class():
	return 'Ghost'


func is_class(type):
	return type == 'Ghost' or .is_class(type)


func _ready():
	set_color(color, 2)
	if do_not_restart:
		$Anim.play('Pulse')


func set_color(index, block_type, garbage=false):
	"""Set the modulation and symbol for standard blocks/triggers.
	
	Arguments:
	index -- the entry in the Colors singleton to get values from
	block_type -- whether the object is a regular Block (0), a Trigger
		(1), or a Diamond (2)
	garbage -- whether or not to override the applied color with gray
		and play an intro animation (default: false)
	
	Because this method relies on a singleton, don't call it from
	an instantiated Block before adding it to a scene.
	"""
	color = index
	
	$Sprite.frame = block_type
	# Diamonds
	if index == -1 or block_type == 2:
		$Sprite.modulate = Color(.9, .9, .9)
		$Sprite/Symbol.hide()
		# Diamonds drop alone, and don't need a pivoting-guide.
		$Sprite/Pointer1.hide()
		$Sprite/Pointer2.hide()
	else:
		$Sprite/Symbol.show()
		
		var C = $'/root/Colors'
		
		$Sprite.modulate = Color(C.blocks[index])
		if garbage:
			#$Sprite.modulate = Color(.4, .4, .4)
			$Sprite.modulate.a = .6
			$Anim.play('Fall')
		else:
			if not partner:
				$Sprite/Pointer1.show()
				$Sprite/Pointer2.show()
			if not do_not_restart:
				$Anim.stop()
				$Anim.play('Pulse')
		$Sprite/Symbol.frame = C.frames[index]


func haunt(p, overwrite=false):
	"""Place the Ghost at the lowest unoccupied point below a point.
	
	Arguments:
	p -- the Vector2 grid-point below which the Ghost will be placed
	overwrite -- whether or not to clear the parent grid's Ghost cache
		before running (default: false)
	
	Starting from point `p`, every row of a parent grid is checked for
	occupation by either a gameplay-affecting object or another Ghost.
	The last unoccupied point found is set as the position for the
	Ghost, and the the parent grid's cache thereof is manually updated.
	If no point below `p` is available, the Ghost is hidden after being
	positioned at `p`.
	
	This method allows the Ghost to potentially exist above y-point 0
	within a parent grid. Ghosts immediately convert into Garbage on
	the next turn of gameplay, and that process will silently pass on
	creating a Garbage piece above 0. A player may move active pieces
	in a way that would push Ghosts above 0 temporarily, and then
	move again to allow the Ghost back into the visible space of the
	parent grid: freeing the Ghosts when this is possible would lead
	to undesired behavior and consequences.
	"""
	if not $'..'.is_class('Grid'):
		return
	
	if overwrite:
		$'..'.ghosts.clear()
		show()
	
	var h = Vector2(p.x, HEIGHT - 1)
	for y in range(p.y + 1, HEIGHT):
		if $'..'.collision(p.x, y, true):
			h.y = y - 1
			break
	
	set_v(h)
	$'..'.ghosts[key()] = self
	if h.y == p.y:
		#hide()
		pass
	else:
		show()


func spawn_block(count=6):
	"""Have the Ghost replace itself with a Garbage object."""
	var b = Garbage.instance()
	b.get_node('Sprite/Number').frame = count
	b.count = count
	var p = point()
	# Only spawn garbage when it's within the real gameplay space.
	if p.y >= 0:
		b.set_v(p)
		$'..'.add_child(b)
		$'..'.garbage[b.key()] = b
		b.set_color(color)
		#b.garbage_flash()
	queue_free()
