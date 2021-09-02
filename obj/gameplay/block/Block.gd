extends GridObject
class_name Block


var orientation = Vector2(0, -1)
var partner = null

export var color = 0
export var is_diamond = false
export var is_trigger = false
export var is_garbage = false
export var exploding = false
export var falling = false

var number = '1'


func get_class():
	return 'Block'


func is_class(type):
	return type == 'Block' or .is_class(type)


func _ready():
	# Perform parent GridObject behavior.
	if snap_on_ready:
		point()
	# Apply variable set within the editor.
	set_color(color)
	
	# Prevent animation-tweaking from breaking the game.
	exploding = false
	
	# Only allow logic to process if within a grid.
	# Shelves are prevented from ever executing logic.
	set_process_input(false)
	if $'..'.is_class('Grid') \
			and get_class() == 'Block':
		# Start acting within the game if dropped in and the match
		# didn't just end for the grid/player.
		if falling and not $'..'.lost:
			deploy($'..')
	
	# Stop Block from shooting down instantly.
	set_process(false);


func set_color(index, _ignore = null):
	"""Set the modulation and symbol for standard blocks/triggers.
	
	Arguments:
	index -- the entry in the Colors singleton to get values from
	_ignore -- ignored; here for the `setting_changed`-signal emitted
		by LobbySettingsItem
	
	Because this method relies on a singleton, don't call it from
	an instantiated Block before adding it to a scene.
	"""
	var C = $'/root/Colors'
	
	# Blocks, Triggers, Garbage, and Diamonds are all unique objects
	# with their own internal structures. Coloration cannot be applied
	# uniformly.
	color = index
	if is_trigger:
		$Sprite/Base.self_modulate = Color(C.blocks[index])
		$Sprite/Symbol.self_modulate = Color(C.blocks[index])
		$Sprite/Shine.self_modulate = Color(C.blocks[index]).lightened(.18)
		$Trail.self_modulate = Color(C.blocks[index])
		
		$Sprite/Symbol.frame = C.frames[index]
	elif is_diamond:
		pass
	elif is_garbage:
		$Sprite.self_modulate = Color(C.blocks[index]).darkened(.1)
		$Sprite/Number.self_modulate = Color(C.blocks[index])
		$Sprite/Symbol.self_modulate = Color(C.blocks[index])
		
		$Sprite/Symbol.frame = C.frames[index]
	else:
		$Sprite.self_modulate = Color(C.blocks[index])
		$Trail.self_modulate = Color(C.blocks[index])
		$Sprite.frame = C.frames[index]


func deploy(grid, speed=1.0):
	"""Add Block to a BlockContainer and commence falling.
	
	Arguments:
	grid -- the new parent object for the Block
	
	This function presumes that the Block is orphaned. If `grid` is not
	a 'Grid', the logic for falling is not engaged. A single partnered
	Block is engaged, if present.
	"""
	# Make doubly sure animation-tweaking doesn't break the game.
	exploding = false
	
	# Allow for an orphaned Block to be deployed on-the-fly.
	if not has_node('..') or grid != $'..':
		grid.add_child(self) # TODO: orphan block before re-parenting
	
	if $'..'.is_class('Grid'):
		number = $'..'.number
		
		$Anim.playback_speed = speed
		$Anim.play('Descend 1')
		$Anim2.play('Flash')
		set_process_input(true)
		for c in get_children():
			if c.is_class('Block'):
				c.get_node('Anim').play('Descend 2')
				partner = c
				break
		# Prevent Diamonds from immediately falling through pieces on
		# row 1 (second from the top).
		if is_diamond:
			$'..'.update()
			var p = point()
			if $'..'.collision(p.x, p.y + 1):
				$Anim.play('Descend 3')
		
		if partner:
			# HOW DOES THIS EVEN GET CHANGED????
			partner.exploding = false
			partner.get_node('Anim').playback_speed = speed
		set_ghosts()


func _slam(instant=false):
	"""Settle Block, stop animations, and progress gamestate.
	
	Arguments:
	instant -- shift the Block all the way down as low as possible in
		one pass; used by controlled Blocks (default: false)
	"""
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	# REMINDER: this should only ever be called on controlled pieces.
	falling = false
	set_process_input(false)
	
	# Settle instantly if the (controlled) Block is stacked vertically.
	if instant:
		$Anim.play('Slam')
		# Make the base Block settle first if it's lower.
		if orientation.y == -1:
			settle(null, true)
	else:
		$Anim.play('Normal')
		# For lateral pairings, let both Blocks begin falling
		# independently, before detonations occur.
		if orientation.x and settle(null, false):
			falling = true
	
	$Anim2.play('Stop')
	
	if partner:
		partner.falling = false
		
		remove_child(partner)
		$'..'.add_child(partner)
		
		# The order of operations here is to prevent a spin-animation
		# from positioning the partnered Block after being re-parented.
		partner.get_node('Anim2').play('Stop')
		partner.position += position
		if instant:
			partner.get_node('Anim').play('Slam')
			partner.settle(null, true)
		else:
			partner.get_node('Anim').play('Normal')
		
		# Settle instantly if the (controlled) Block pair is stacked
		# vertically.
		if instant:
			# Have the base Block settle after its partner if they're
			# aligned on the x-axis or the partnered Block is lower.
			if orientation.y != -1:
				settle(null, true)
		else:
			# Same lateral-case check as above, for the partner.
			if orientation.x and partner.settle(null, false):
				partner.falling = true
	
	# Diamonds will ALWAYS explode upon landing and trigger the next
	# turn via the standard explosion process.
	var diamond_explosions = 0
	if is_diamond:
		var p = point()
		var below = $'..'.collision(p.x, p.y + 1)
		# If the Diamond lands on another piece, explode every piece
		# in the parent BlockContainer of the same color.
		if typeof(below) != TYPE_BOOL:
			var c = below.color
			for block in $'..'.get_children():
				if block.is_class('Block') \
						and block.color == c:
					# REMINDER: `explode()` handles grid-management.
					block.explode(false)
					diamond_explosions += 1
		explode(false)
		# Override re-settling animation with Diamond-specific variant.
		if diamond_explosions > 0:
			grid.play('Re-settle All')
	
	# Everything is settled, so progress the gamestate.
	if not falling \
			and (not partner or not partner.falling) \
			and diamond_explosions == 0:
		next_turn()
	
	# Clear out obsolete data.
	# TODO: delete shadows and animators, etc.
	partner = null


func next_turn():
	"""Trigger the parent Grid's end-turn logic."""
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	# On the first attempt at ending the turn, tick down Garbage.
	# If any garbage ticks down to zero, let it take care of end-turn
	# logic.
	if not grid.countdown():
		grid.update()
		grid.shelve()
		
		if grid.detonate():
			pass
		else:
			grid.play('Next Turn')
	
	grid.render_ghosts()


const HALF_PI = PI / 2


func _input(event):
	var p = point()
	# Accommodate both the base Block and a potential partner.
	var p2 = p
	if partner:
		p2 = p + orientation
	
	# Temporary testing command
	if event.is_action_pressed(number + '_test'):
		pass
		#get_tree().paused = true)
		#$'..'.add_garbage()
	
	# ~~ VERTICAL MOVEMENT ~~
	if event.is_action_pressed(number + '_slam'):
		_slam(true)
	elif event.is_action_pressed(number + '_fast_fall'):
		# Fast-falling is something done via tapping in Comback: the
		# Block instantly cuts to the end of its current falling-loop
		# and attempts to drop down a single row.
		$Anim.seek(0, true)
		if partner:
			partner.get_node('Anim').seek(0, true)
		descend()
	
	# ~~ LATERAL MOVEMENT ~~
	var movement_occurred = false
	if event.is_action_pressed(number + '_move_left'):
		# Only move if all partnered pieces an also move.
		if not $'..'.collision(p.x - 1, p.y) \
				and not $'..'.collision(p2.x - 1, p2.y):
			p = move(-1, 0)
			movement_occurred = true
	if event.is_action_pressed(number + '_move_right'):
		# Only move if all partnered pieces an also move.
		if not $'..'.collision(p.x + 1, p.y) \
				and not $'..'.collision(p2.x + 1, p2.y):
			p = move(1, 0)
			movement_occurred = true
	
	if movement_occurred:
		# Toggle Diamonds between their static and gradual descent
		# animations as necessary.
		if is_diamond:
			# To keep stalling from being TOO easy, moving *onto*
			# another piece will not fully reset the descent.
			if $'..'.collision(p.x, p.y + 1):
				var f = $Anim.current_animation_position
				$Anim.play('Descend 3')
				$Anim.seek(f)
			else:
				$Anim.play('Descend 1')
		$'..'.render_ghosts()
	
	# ~~ SPINNING ~~
	if partner:
		var spin = ''
		if $'/root/Controls'.relative_rotation[int(number) - 1]:
			if event.is_action_pressed(number + '_rotate_cw'):
				spin = 'CW'
			if event.is_action_pressed(number + '_rotate_ccw'):
				spin = 'CCW'
		else:
			# Prevent redundant spinning.
			if event.is_action_pressed(number + '_rotate_n'):
				if orientation.y != -1:
					spin = 'N'
			if event.is_action_pressed(number + '_rotate_s'):
				if orientation.y != 1:
					spin = 'S'
			if event.is_action_pressed(number + '_rotate_e'):
				if orientation.x != 1:
					spin = 'E'
			if event.is_action_pressed(number + '_rotate_w'):
				if orientation.x != -1:
					spin = 'W'
		
		# Each direction follows a simple logic: if something is
		# preventing the partner Block from spinning to the specified
		# orientation, attempt to push the base Block in the opposite
		# direction.
		#
		# If something is in the way of pushing the base Block, do not
		# attempt the spin, and exit the function. Clock-orientented
		# rotations will, if unable to execute, do another rotation:
		# even in the tightest of situations, the Block-pair will
		# simply end up swapping positions.
		
		var clock_rotation = 0
		
		match spin:
			'N':
				if $'..'.collision(p.x, p.y - 1):
					if $'..'.collision(p.x, p.y + 1):
						return
					p = move(0, 1)
				orientation = Vector2(0, -1)
			'S':
				if $'..'.collision(p.x, p.y + 1):
					if $'..'.collision(p.x, p.y - 1):
						return
					p = move(0, -1)
				orientation = Vector2(0, 1)
			'E':
				if $'..'.collision(p.x + 1, p.y):
					if $'..'.collision(p.x - 1, p.y):
						return
					p = move(-1, 0)
				orientation = Vector2(1, 0)
			'W':
				if $'..'.collision(p.x - 1, p.y):
					if $'..'.collision(p.x + 1, p.y):
						return
					p = move(1, 0)
				orientation = Vector2(-1, 0)
			'CW':
				clock_rotation = HALF_PI
			'CCW':
				clock_rotation = -HALF_PI
		
		if clock_rotation:
			var o = orientation.rotated(clock_rotation)
			o.x = int(round(o.x))
			o.y = int(round(o.y))
			if $'..'.collision(p.x + o.x, p.y + o.y):
				if $'..'.collision(p.x - o.x, p.y - o.y):
					o = o.rotated(clock_rotation)
					o.x = int(round(o.x))
					o.y = int(round(o.y))
					if $'..'.collision(p.x + o.x, p.y + o.y):
						p = move(-o.x, -o.y)
				else:
					p = move(-o.x, -o.y)
			
			orientation = o
			if orientation.y == -1:
				spin = 'N'
			elif orientation.x == 1:
				spin = 'E'
			elif orientation.y  == 1:
				spin = 'S'
			else:
				spin = 'W'
		
		if spin != '':
			partner.get_node('Anim2').play('Spin ' + spin)
			$'..'.render_ghosts()


func set_ghosts():
	"""Place the Ghosts showing where the Block will fall.
	
	This method will clear the parent BlockContainer's cache of
	Ghosts. `set_ghosts()` is designed to be called at the beginning
	of BlockContainer's `render_ghosts()`.
	"""
	var p = point()
	if partner:
		var g = point() + orientation
		if orientation.y <= 0:
			$'../Ghost1'.haunt(p, true)
			$'../Ghost2'.haunt(g)
		else:
			$'../Ghost2'.haunt(g, true)
			$'../Ghost1'.haunt(p)
	else:
		$'../Ghost1'.haunt(p, true)
		$'../Ghost2'.hide()


func descend():
	"""Determine if the Block can fall down one space.
	
	The Block (and partner's) animation 'Stop' will play if either
	piece is unable to fall further. A partnered Block will be
	re-parented to the same parent as the base Block before playing
	its animation.
	
	Should the descent fail, the parent (assumed to be a Grid) will
	play their 'End Turn' animation. The Block(s) will settle
	independently before the animation, to prevent hanging shelves.
	"""
	var p = point()
	# Accommodate both the base Block and a potential partner.
	var p2 = p
	if partner:
		p2 = p + orientation
	
	# Stop falling if there's something in the way.
	if $'..'.collision(p.x, p.y + 1) \
			or $'..'.collision(p2.x, p2.y + 1):
		_slam()
	else:
		p = move(0, 1)
		# Manually resetting the shadow smooths faster playback speeds.
		if not is_diamond:
			$Shadow.position.y = 0
	
	# Because Diamonds fall gradually, they have to make sure that
	# they don't start overlapping pieces beneath them or float out of
	# bounds.
	if is_diamond:
		if falling:
			# Switch to the static descent animation.
			if $'..'.collision(p.x, p.y + 1):
				var f = $Anim.current_animation_position
				$Anim.play('Descend 3')
				$Anim.seek(f)
		else:
			# Ensure the Diamond is sitting squarely where it landed.
			$Sprite.position.y = 0


func tally_settlement(add=true):
	"""Add/remove this Block from the parent Grid's register of
	falling pieces.
	
	Arguments:
	add -- whether to add or remove the Block (default: true)
	"""
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	if(add):
		if not grid.settling_pieces.has(self):
			grid.settling_pieces.push_back(self)
	else:
		var found = grid.settling_pieces.find(self)
		if found > -1:
			grid.settling_pieces.remove(found)


func settle(grid=null, instant=false):
	"""Drop the Block to the lowest empty spot possible.
	
	Arguments:
	grid -- the BlockContainer that should be examined (default: null)
	instant -- whether or not to move the piece down as many rows as
		possible (default: false)
	
	This method controls the `falling` property, and calls the grid's
	`update()` method after re-positioning.
	
	The Block's parent is used for a grid if none is supplied as an
	argument; used in `descend()` on partnered blocks.
	"""
	set_process_input(false)
	
	if not grid:
		grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	if instant:
		var p = point()
		for y in range(p.y + 1, HEIGHT):
			if grid.collision(p.x, y):
				set_y(y - 1)
				break
			else:
				set_y(y)
		grid.update()
	else:
		var p = point()
		if not grid.collision(p.x, p.y + 1):
			set_process(true)
			tally_settlement()
			return true
		else:
			falling = false


# warning-ignore:unused_argument
func _process(delta):
	"""Try to move down a single row; trigger next turn otherwise, if
	no other game-pieces are also settling.
	
	Arguments:
	delta -- the amount of time that has passed since the last frame
		(ignored by Block)
	"""
	# Shelves call this alongside their own `_process(), so this blocks
	# any funny business from going down.
	if is_class('Shelf'):
		return
	
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	var p = point()
	if not grid.collision(p.x, p.y + 1):
		grid.remove(self)
		move(0, 1)
		grid.add(self)
	else:
		falling = false
		
		for y in range(p.y - 1, -3, -1):
			var next = grid.collision(p.x, y)
			if next and not next is bool: # TODO check if previously freed
				next.settle()
				break
		
		tally_settlement(false)
		if grid.settling_pieces.size() == 0:
			next_turn()
		
		set_process(false)


func detonate():
	"""Trigger explosions in any adjacent pieces of the same color.
	
	Returns:
	int -- the number to tally this detonation with (0 or 1)
	"""
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	var p = point()
	
	if is_diamond:
		return
	
	# Look at each directly adjacent grid-space.
	for P in [[p.x - 1, p.y], [p.x + 1, p.y],\
			[p.x, p.y - 1], [p.x, p.y + 1]]:
		var g = grid.collision(P[0], P[1])
		# Do nothing in the case of an empty point or wall.
		if typeof(g) == TYPE_BOOL:
			continue
		
		# An adjacent Garbage block won't trigger an explosion. They
		# DO get consumed in nearby explosions, but that's later.
		if g.color == color and not g.is_garbage:
			# Prevent recursion.
			if not exploding:
				explode()
			
			exploding = true
			
			g.get_node('Anim').playback_speed = 1
			g.get_node('Anim').play('Explode')
	# Report that a chain reaction has occurred, for the sake of
	# continuing a re-settling cycle.
	if exploding:
		# Explode adjacent garbage blocks.
		for P in [[p.x - 1, p.y], [p.x + 1, p.y],\
				[p.x, p.y - 1], [p.x, p.y + 1]]:
			var g = grid.collision(P[0], P[1])
			# Another empty-point check.
			if typeof(g) == TYPE_BOOL:
				continue
			# Here is where adjacent Garbage pieces are blown up.
			if g.is_garbage:
				g.get_node('Anim').play('Explode')
		return 1
	else:
		return 0


const BlockExplosion \
	= preload('res://obj/gameplay/block/explosion/BlockExplosion_GLES2.tscn')


func explode(apply_bonus=true):
	"""Spawn an Explosion object, and remove self from gameplay."""
	$Anim.playback_speed = 1
	
	var grid = $'..'
	if not grid.is_class('Grid'):
		return
	
	if grid.active_piece == self:
		grid.active_piece = null
	
	# Remove garbage/add to offensive payload.
	# Neither simply dropping a Diamond, nor clearing out garbage,
	# will count in a player's favor.
	if not is_diamond and not is_garbage:
		if apply_bonus:
			# Report height of Block.
			var p = point()
			if grid.height_bonus > p.y:
				grid.height_bonus = p.y
			grid.remove_garbage(1, true)
		else:
			grid.remove_garbage(1)
	
	# Remove the Block from the parent grid's caches.
	var k = key()
	grid.blocks.erase(k)
	if is_trigger:
		grid.triggers.erase(k)
	if is_garbage:
		grid.garbage.erase(k)
	if is_diamond:
		grid.diamond = null
		# Accommodate Diamonds' instant explosion mucking up the order
		# of turn-operations by using a hard override.
		$'../Ghost1'.hide()
	
	# Only cause cosmetic explosions on pieces within visible space.
	if position.y >= 0 and position.y < HEIGHT * SIZE:
		var e = BlockExplosion.instance()
		e.position = position
		e.get_node('Audio').pitch_scale = 1.0 + rand_range(.1, .4)
		if grid.explosion_layer:
			grid.explosion_layer.add_child(e)
		else:
			grid.add_child(e)
	
	# Progress gamestate.
	grid.play('Re-settle')
	
	queue_free()


# This property is kept all the way down here because it only has any
# bearing inside of the method below. Most all of this script is only
# used by Garbage blocks, so isolating this bit of Garbage-exclusive
# data helps to isolate and maintain it all.
var count = 0


func countdown(logic_pass=true):
	"""Tick down Garbage piece and potentially affect turn-logic.
	
	Arguments:
	logic_pass -- specify if this call affects the turn (default: true)
	
	Logical passes will only affect the Garbage if the piece hits zero
	on its count. This method is only called in a batch of Garbage
	objects: if any one of them reach zero, the parent grid doing the
	batch of calls will switch to its 'Garbage Conversion' animation.
	
	When the next active piece is brought in by the parent grid, this
	method is called again with `logic_pass` set to false, meaning that
	the piece is syncronized with all other Garbage in a pulsing
	animation.
	
	The internal `count` property only ticks down during logical
	passes. The 'Count Down' animation is only ever triggered during
	cosmetic passes.
	
	Returns:
	int -- binary of whether or not this Garbage reached zero
	"""
	if not is_garbage:
		return 0
	
	if logic_pass:
		count -= 1
		if count <= 0:
			$Sprite/Number.frame = 0
			$Anim.play('Zero')
			return 1
		else:
			return 0
	else:
		$Sprite/Number.frame = count
		$Anim.stop(true)
		$Anim.play('Count Down')
		return 0


const GarbageFlash = \
	preload('res://obj/gameplay/block/garbage/GarbageFlash.tscn')


func _replace():
	"""Free a Garbage piece and replace it with a standard Block."""
	if not is_garbage:
		return
	
	# Create new Block.
	var b = load('res://obj/gameplay/block/Block.tscn').instance()
	b.set_v(point())
	$'..'.add_child(b)
	# REMINDER: Singletons can't be accessed without being in-game.
	b.set_color(color)
	
	# Manually update the parent grid's caches.
	$'..'.blocks[key()] = b
	$'..'.garbage.erase(key())
	
	# Spawn SFX.
	var e = GarbageFlash.instance()
	e.position = position
	#e.get_node('Audio').pitch_scale = 1.0 + rand_range(.1, .4)
	$'..'.add_child(e)
	
	queue_free()
