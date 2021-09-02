extends GridObject
class_name BlockContainer


const Block = preload('res://obj/gameplay/block/Block.tscn')
const Shelf = preload('res://obj/gameplay/block/shelf/Shelf.tscn')
const Trigger = preload('res://obj/gameplay/block/trigger/Trigger.tscn')
const Diamond = preload('res://obj/gameplay/block/diamond/Diamond.tscn')

signal reset

export var number = '1'
export(int, 0, 6) var color = 0
export var auto_start = false

var active_piece = null
var blocks = {}
var triggers = {}
var diamond = null

# warning-ignore:unused_class_variable
var settling_pieces = [] # used by settlings Blocks

const Ghost = preload('res://obj/gameplay/block/ghost/Ghost.tscn')
var ghosts = {}
var garbage = {}
var incoming_garbage = []
var outgoing_garbage = 0
var height_bonus = HEIGHT

var lost = false
var game_over = false

export(NodePath) var explosion_layer
export(NodePath) var source
export(NodePath) var stats
export(NodePath) var game_mode
export(NodePath) var scoreboard

var starting_speed = 1.0
var speed = 1.0
var speed_increment = .015
var time_played = 0
var score = 0
var offense = 1
var defense = 1

enum GARBAGE_MODIFIER {NORMAL, ALL_BLACK, ALL_WHITE, ALL_COLORS}
var garbage_modifier_in = GARBAGE_MODIFIER.NORMAL
var garbage_modifier_out = GARBAGE_MODIFIER.NORMAL

var chain_multiplier = 1


func get_class():
	return 'Grid'


func is_class(type):
	return type == 'Grid' or .is_class(type)


func _ready():
	# Stop the game-timer from starting immediately.
	set_process_input(false)
	
	if explosion_layer:
		explosion_layer = get_node(explosion_layer)
	if source:
		source = get_node(source)
	
	if game_mode:
		game_mode = get_node(game_mode)
	
	# This gets overwritten by Player, but this is good for testing.
	$Cursor.number = number
	
	randomize()
	
	for x in WIDTH:
		incoming_garbage.append([])
	
	speed = starting_speed
	update()
	
	if auto_start:
		add_piece()
	
	if stats:
		stats = get_node(stats)
		if stats.has_node('Speed/Text'):
			stats.get_node('Speed/Text').text = str(speed) + '×'
	else:
		stats = null
	
	set_process(false)


func apply_settings(settings : GameplaySettings):
	"""TODO"""
	number = str(settings.number)
	$Cursor.number = number
	
	starting_speed = settings.starting_speed
	speed_increment = settings.speed_increment
	offense = settings.offense_multiplier
	defense = settings.defense_multiplier
	
	garbage_modifier_in = settings.group_garbage_in
	garbage_modifier_out = settings.group_garbage_out
	
	var c = $'/root/Colors'.ui[settings.color]
	$Cursor.self_modulate = c
	$Cursor/TrailL.self_modulate = c
	$Cursor/TrailR.self_modulate = c
	$Result/Shadow.modulate = c


func _process(delta):
	"""TODO"""
	if not stats.visible:
		set_process(false)
		return
	
	time_played += delta
	
	var seconds = stepify(fmod(time_played, 60), .1)
	var minutes = int(time_played / 60)
	var hours = str(int(minutes / 60))
	
	if seconds < 10:
		seconds = '0' + str(seconds)
	else:
		seconds = str(seconds)
	if seconds.length() == 2:
		seconds += '.0'
	
	if minutes < 10:
		minutes = '0' + str(minutes)
	
	stats.get_node('Time/Text').text = \
		hours + ':' + str(minutes) + ':' + seconds
	
	var m = time_played / 60
	if m < 1:
		m = 1
	var average = str(stepify(score / m, .01))
	
	var d = average.split('.')
	if d.size() == 1:
		average += '.00'
	elif d[1].length() == 1:
		average += '0'
	
	if stats.has_node('Average/Text'):
		stats.get_node('Average/Text').text = average + ' / min.'


# This pattern is the default pattern used in games with more than 2
# players.
var GARBAGE_PATTERN = [[2, 3, 0, 1, 2, 3, 0]]


func _create_garbage_block(x, y, mod):
	"""Spawn, configure, and insert a Ghost object.
	
	Arguments:
	x -- which column in which to add the garbage
	y -- how far up in the pool the garbage will be
	mod -- TODO
	
	This method will create and insert a garbage Ghost; that Ghost's
	color being determined by the coordinates provided as arguments.
	The coordinates are where the Ghost would end up occupying in the
	BlockContainer's pool of Ghosts upon insertion. A y-value of 0 is
	considered the bottom of the pool.
	
	The color of the object is determined by where in the repeating
	garbage pattern it would end up appearing.
	"""
	var row = 0
	if y:
		row = y % GARBAGE_PATTERN.size()
	var block_color : int
	
	match mod:
		GARBAGE_MODIFIER.ALL_BLACK:
			block_color = 5
		GARBAGE_MODIFIER.ALL_WHITE:
			block_color = 6
		GARBAGE_MODIFIER.ALL_COLORS:
			block_color = x % 5
		_:
			block_color = GARBAGE_PATTERN[row][x]
	
	match garbage_modifier_in:
		GARBAGE_MODIFIER.ALL_BLACK:
			block_color = 5
		GARBAGE_MODIFIER.ALL_WHITE:
			block_color = 6
		GARBAGE_MODIFIER.ALL_COLORS:
			block_color = x % 5
	
	var g = Ghost.instance()
	# Manually push the Ghost's sprite above the visual area to prevent
	# a flicker as its falling animation starts.
	g.get_node('Sprite').position.y = -1120
	add_child(g)
	incoming_garbage[x].append(g)
	g.set_color(block_color, 0, true)
	g.haunt(Vector2(x, -1))


func add_garbage(amount, modifier):
	"""Evenly add Ghosts to the grid.
	
	Arguments:
	amount -- the number of Ghosts to add to the grid
	modifier -- TODO
	
	This method fills in gaps at the top of the collective columns of
	Ghosts, to make an even row. After attempting to create as many
	complete rows as possible, a row of randomly-placed Ghosts is
	added.
	
	The method will maintain a repetition of its stored garbage
	pattern.
	
	This is meant to be the ONLY way to add Ghosts! If another method
	adds Ghosts to the BlockContainer, and a column ends up with more
	than 1 extra Ghost than the others, this method WILL NOT work to
	balance out the columns: it will only behave strangely.
	"""
	amount *= defense
	# PHASE ZERO: Idiot check
	if amount == 0 or lost:
		return
	
	randomize()
	
	# PHASE ONE: Determine and complete topmost row.
	var top = 0
	var bottom = 0
	var gaps = []
	for x in WIDTH:
		var s = incoming_garbage[x].size()
		if s >= top:
			top = s
		else:
			bottom = s
			gaps.append(x)
	
	# Catch rows filled in contiguously on the right.
	if not gaps.size():
		for x in WIDTH:
			var s = incoming_garbage[x].size()
			if s < top:
				gaps.append(x)
				bottom = s
	
	if gaps.size():
		# Fill in any oversights from the left when there's a
		# central gap.
		for x in WIDTH:
			if incoming_garbage[x].size() < top \
					and not gaps.count(x):
				gaps.append(x)
		
		if amount < gaps.size():
			gaps.shuffle()
		
		for g in gaps:
			_create_garbage_block(g, bottom, modifier)
			amount -= 1
			if amount == 0:
				return
	
	# PHASE TWO: Add full rows.
	var rows = int(amount / WIDTH)
	for r in rows:
		for x in WIDTH:
			_create_garbage_block(x, top, modifier)
			amount -= 1
			if amount == 0:
				return
		top += 1
	
	# PHASE THREE: Add remaining garbage randomly.
	var columns = []
	for x in WIDTH:
		columns.append(x)
	columns.shuffle()
	for c in columns:
		_create_garbage_block(c, top, modifier)
		amount -= 1
		if amount == 0:
			return


func _bonus():
	"""Returns a height bonus value from 0 to 3; applied per-block."""
	var hb = (HEIGHT - height_bonus) - WIDTH
	if hb < 0:
		hb = 0
	return int(hb / 2)


func remove_garbage(amount, bonus=false):
	"""Remove Ghosts, start from the topmost layer.
	
	Arguments:
	amount -- the number of Ghosts to remove
	bonus -- whether or not to remove more pieces with the height
		bonus (default: false)
	
	This method will repeatedly call itself, removing only from the
	topmost layer of Ghosts on each pass. `amount` is reduced and
	passed to each recursive method call. If there is a point where the
	number of Ghosts in the topmost row is greater than `amount`, a
	random selection of Ghosts is removed.
	"""
	if amount == 0:
		return
	
	if bonus:
		amount *= _bonus() + 1
	
	var top = 0
	var top_row = []
	for x in WIDTH:
		var s = incoming_garbage[x].size()
		if s > top:
			top = s
			top_row.clear()
			top_row.append(incoming_garbage[x])
		elif s == top:
			top_row.append(incoming_garbage[x])
	
	if top == 0:
		outgoing_garbage += amount
		return
	
	top_row.shuffle()
	
	while(top_row.size()):
		var column = top_row.pop_back()
		column.pop_back().queue_free()
		amount -= 1
		if amount == 0:
			return
	
	if amount:
		remove_garbage(amount)


func render_ghosts(new_active_piece=null, hide_ghosts=false):
	"""Go through each column of `incoming_garbage` and place them.
	
	Arguments:
	new_active_piece -- a potential new falling game piece to observe
		(default: null)
	hide_ghosts -- whether or not to place the active-piece ghosts
		outside of the BlockContainer's visible range (default: false)
	
	`incoming_garbage` is a 2D array, holding columns of Ghosts which
	represent Garbage pieces to spawn on the next turn, all ordered
	from lowest to highest. This method cycles through each column in
	order and calls `haunt()` within their respective x-coordinates and
	up at a y-value of -1.
	
	If a new `active_piece` is provided, its `set_ghosts()` method is
	called first to ensure its landing position is displayed properly.
	"""
	if new_active_piece:
		active_piece = new_active_piece
	else:
		# Ensure the method is working with blank slate.
		ghosts.clear()
	
	if active_piece:
		active_piece.set_ghosts()
	else:
		# Hide the active-piece ghosts during chain reactions.
		$Ghost1.hide()
		$Ghost2.hide()
	
	for x in WIDTH:
		for y in range(incoming_garbage[x].size()):
			incoming_garbage[x][y].haunt(Vector2(x, -1))
	
	if hide_ghosts:
		$Ghost1.set_y(-1)
		$Ghost2.set_y(-1)


func play(anim):
	"""A shortcut mainly for restarting animations with $Anim."""
	$Anim.stop()
	$Anim.play(anim)


func add(game_piece):
	"""TODO"""
	var k = game_piece.key()
	
	if game_piece.is_class('Shelf'):
		for kk in k:
			blocks[kk] = game_piece
	else:
		blocks[k] = game_piece
		if game_piece.is_trigger:
			triggers[k] = game_piece
		if game_piece.is_garbage:
			garbage[k] = game_piece


func remove(game_piece):
	"""TODO"""
	var k = game_piece.key()
	
	if game_piece.is_class('Shelf'):
		for kk in k:
			blocks.erase(kk)
	else:
		blocks.erase(k)
		if game_piece.is_trigger:
			triggers.erase(k)
		if game_piece.is_garbage:
			garbage.erase(k)


func update():
	"""Refresh the dictionaries tracking the grid's stationary blocks."""
	# Clear descriptive dictionary of objects.
	blocks.clear()
	triggers.clear()
	garbage.clear()
	diamond = null
	
	# Refill dictionaries with inactive objects.
	for block in get_children():
		if block.is_class('Ghost'):
			ghosts[block.key()] = block
			continue
		
		if not block.is_class('Block') \
				or block.exploding \
				or block.is_queued_for_deletion():
			continue
		
		if block.falling:
			active_piece = block
			continue
		
		if block.is_class('Shelf'):
			for k in block.key():
				blocks[k] = block
			continue
		
		blocks[block.key()] = block
		if block.is_trigger:
			triggers[block.key()] = block
		if block.is_garbage:
			garbage[block.key()] = block
		if block.is_diamond:
			diamond = block


func clear():
	"""Remove all pieces and garbage; reset 1P stats."""
	active_piece = null
	for c in get_children():
		if c.is_class('Block') \
				or (c.is_class('Ghost') and not c.persistent):
			c.queue_free()
	for c in incoming_garbage:
		c.clear()
	outgoing_garbage = 0
	update()
	render_ghosts(null, true)
	
	speed = starting_speed
	score = 0
		
	if stats != null:
		time_played = 0
		if stats.has_node('Speed/Text'):
			stats.get_node('Speed/Text').text = str(speed) + '×'
		
		stats.get_node('Time/Text').text = '0:00:00.0'
		stats.get_node('Score/Text').text = '0'
		
		if stats.has_node('Average/Text'):
			stats.get_node('Average/Text').text = '0.00 / min.'
	
	$Anim.stop()


func collision(x, y, g=false):
	"""Check if a given point is occupied or in-bounds.
	
	Arguments:
	x -- the x-coordinate of the grid to examine
	y -- the y-coordinate of the grid to examine
	g -- whether or not to include Ghosts in check (default: false)
	"""
	var k = str(x) + ',' + str(y)
	if x < 0 or x > WIDTH - 1 or y > HEIGHT - 1:
		return true
	elif blocks.has(k):
		return blocks[k]
	elif g and ghosts.has(k):
		return ghosts[k]
	
	return false


func shelve():
	"""Go through each row of the grid and combine any 3+ Blocks of the
	same color.
	
	Important to note is that this method is meant to be called both
	before AND after the application of gravity via `settle()`: this
	is to maximize the potential score in potential detonations when
	placing pieces. `settle()` will also call `shelve()` again after
	it's done.
	
	The descriptive dictionary monitoring game-pieces is manipulated
	within this method, removing the need for a call to `update()`.
	"""
	# Because shelving only begins occurring when an active game piece
	# relinquishes control, `active_piece` is automatically unset for
	# the sake of ensuring `render_ghosts()` runs smoothly.
	active_piece = null
	
	for y in range(HEIGHT):
		var bar = []
		var _color = -1
		# Scans of rows go one beyond the end of allow evaluations to
		# trigger when the rightmost column is occupied.
		for x in range(WIDTH + 1):
			var next_block = false
			if x < WIDTH:
				next_block = collision(x, y)
			# Compile as many contiguous blocks/shelves as possible
			# before allowing an evaluation to occur.
			# TODO find error here (is_instance_valid() is a crapshot)
			if is_instance_valid(next_block) \
					and (next_block.color == _color or _color == -1) \
					and not next_block.is_trigger \
					and not next_block.is_diamond \
					and not next_block.is_garbage:
				_color = next_block.color
				# This check prevents a Shelf from being added more
				# than once.
				if not bar.count(next_block):
					bar.append(next_block)
				continue
			
			# This check prevents an already-present Shelf from
			# remaking itself.
			if bar.size() > 1:
				var length = 0
				for b in bar:
					# Add the length of a present shelf or increment.
					if b.is_class('Shelf'):
						length += b.length
					else:
						length += 1
				# Instantiate and recognize a new Shelf, if possible.
				if length >= 3:
					var s = Shelf.instance()
					s.set_length(length)
					s.position = bar[0].position
					s.get_node('Body/Symbol').frame = \
						$'/root/Colors'.frames[_color]
					add_child(s)
					s.set_color(_color)
					# Overwrite previous pieces with the new Shelf.
					for k in s.key():
						blocks[k] = s
					for b in bar:
						b.queue_free()
			
			# Set up for another attempt.
			bar.clear()
			if next_block \
					and not next_block.is_trigger \
					and not next_block.is_diamond \
					and not next_block.is_garbage:
				_color = next_block.color
				bar.append(next_block)
			else:
				_color = -1


func detonate():
	"""Call each trigger piece's `detonate()` method; possibly reset
	end-turn logic cycle.
	
	When executing end-of-turn logic, `detonate()` is called last. The
	first animation, 'End Turn', can be stopped and supplanted by 
	'Re-settle' if any of the triggers start a chain reaction. A cycle
	of settling and detonating will continue until no more chain
	reactions occur.
	"""
	var hits = 0
	for t in triggers.keys():
		# REMINDER: If a Block explodes, it will perpetuate gameplay
		# cycling within its `explode()` method.
		hits += triggers[t].detonate()
	
	return hits


func _send_garbage():
	"""TODO"""
	# At the end of each explosion, send out garbage to opponents.
	var m = chain_multiplier
	if outgoing_garbage:
		speed += speed_increment
		
		score += outgoing_garbage * m
		if stats:
			stats.get_node('Score/Text').text = str(score)
			if stats.has_node('Speed/Text'):
				stats.get_node('Speed/Text').text = str(speed) + '×'
		
		if game_mode is GameMode:
			m *= offense
			game_mode.send_garbage \
				(color, number, outgoing_garbage * m, garbage_modifier_out)
		
		outgoing_garbage = 0
		# Reset the height bonus with each step of a chain reaction.
		height_bonus = HEIGHT
		# Keep increasing the chain multiplier until `add_piece()`
		# resets it.
		chain_multiplier += 1


func settle():
	"""TODO"""
	_send_garbage()
	update()
	
	# Loop from the bottom row to two rows above the top of the visible
	# space, to ensure that new pieces don't spawn on top of pieces
	# users have cleverly stacked above the top of the grid.
	var falls = 0
	for x in range(WIDTH):
		for y in range(HEIGHT - 1, -3, -1):
			var b = collision(x, y)
			if not b or typeof(b) == TYPE_BOOL:
				continue
			
			if b.settle(self):
				falls += 1
				break
	
	if falls == 0:
		shelve()
		if not detonate():
			# REMINDER: `detonate()` triggers `explode()`, which will
			# progress gameplay.
			play('Next Turn')
		render_ghosts()


func settle_all():
	_send_garbage()
	update()
	
	var falls = 0
	for c in get_children():
		if not c.is_class('Block'):
			continue
		
		if c.settle(self):
			falls += 1
	
	if falls == 0:
		shelve()
		if not detonate():
			# REMINDER: `detonate()` triggers `explode()`, which will
			# progress gameplay.
			play('Next Turn')
		render_ghosts()


var countdown_okay = true


func countdown():
	"""Perform a logical pass on garbage; perfom end-turn logic."""
	# Since this gets called each time a Block/Shelf is done falling,
	# a check is put in place to only allow this to run once per turn.
	if not countdown_okay:
		return
	
	var gc = 0
	for g in garbage.values():
		gc += g.countdown()
	if gc:
		$Anim.play('Garbage Conversion')
		return true
	else:
		# If no chain reaction starts, proceeed in end-turn logic.
		shelve()
		if not detonate():
			# REMINDER: `detonate()` triggers `explode()`, which will
			# progress gameplay.
			play('Next Turn')
	
	countdown_okay = true


func _input(event):
	if event.is_action_pressed('1_pause'):
		get_tree().paused = false
	# Start a match with the "confirm"-key.
	# This turns off input processing until being reset by the Player.
	if event.is_action_pressed(number + '_confirm'):
		# This signal is connected to programmatically within Player.
		emit_signal('reset')
		# Player calls these same methods, but they're kept here for
		# the sake of any future unit testing.
		$Result.hide()
		set_process_input(false)


var diamond_count = 11
var dc = 0


func add_piece(start_game=false):
	"""At the end of all turn logic, add another game piece."""
	chain_multiplier = 1
	countdown_okay = true
	
	if start_game:
		lost = false
		game_over = false
		if source:
			source.clear()
		# Make absolutely sure there's no residual garbage, in or out.
		clear()
		
		if stats:
			set_process(true)
	
	# Count how many pieces of garbage are set to fall into the field.
	var total_garbage = 0
	for gx in range(incoming_garbage.size()):
		total_garbage += incoming_garbage[gx].size()
	
	# Tone down garbage-block lifespan according to amount sent.
	var countdown = 5
	if total_garbage > WIDTH * 4:
		countdown = 3
	elif total_garbage > WIDTH * 2:
		countdown = 4
	
	# Spawn incoming garbage.
	for gx in range(incoming_garbage.size()):
		for gy in range(incoming_garbage[gx].size()):
			incoming_garbage[gx][gy].spawn_block(countdown)
		incoming_garbage[gx].clear()
	
	if total_garbage:
		update()
		shelve()
	
	# Do a cosmetic pass on all garbage countdowns.
	# The logical pass occurs before `add_piece()` is called.
	for g in garbage.values():
		g.countdown(false)
	
	# End the game for this BlockContainer if its Cursor is obstructed.
	var cp = $Cursor.point()
	if collision(cp.x, cp.y):
		# In testing, simply clear the field and allow further play.
		#clear()
		dc = 0
		lost = true
		
	#	if game_mode is GameMode:
	#		game_mode.loss()
		if game_mode.report_loss(self) == -1:
			lose()
		
		game_over = true
		set_process(false)
		return
	
	# If an errant animation triggers a call to `add_piece()` after the
	# game has concluded for the BlockContainer, and the Cursor was
	# moved into an unoccupied space, this check prevents any further
	# pieces from being spawned in.
	if game_over:
		return
	
	# In production gameplay, pull a new game piece from a Queue and
	# deploy it within the grid.
	if source:
		var next = source.pop()
		next.position.x = 80 * cp.x
		
		next.deploy(self, speed)
		
		if next.partner:
			$Ghost1.set_color(next.color, int(next.is_trigger))
			$Ghost2.set_color(
				next.partner.color, int(next.partner.is_trigger))
		else:
			$Ghost1.set_color(-1, 2)
		
		render_ghosts(next)
		return
	
	###################################
	#                                 #
	# ~*~ UNIT TESTING GENERATION ~*~ #
	#                                 #
	###################################
	
	randomize()
	
	# Produce a Diamond after N turns.
	dc += 1
	if dc == diamond_count:
		dc = 0
		var d = Diamond.instance()
		d.position.x = 80 * 3
		d.falling = true
		add_child(d)
		$Ghost1.set_color(-1, 2)
		render_ghosts(d)
		return
	
	# Pieces have a 20% chance of being a trigger.
	var t1 = randi() % 5
	var t2 = randi() % 5
	
	var c1 = randi() % 5
	var c2 = randi() % 5
	
#	t1 = 1
#	t2 = 2
	
#	c1 = 2
#	c2 = 0
	
	var b1
	if t1 <= 1:
		b1 = Trigger.instance()
		$Ghost1.set_color(c1, 1)
	else:
		b1 = Block.instance()
		$Ghost1.set_color(c1, 0)
	var b2
	if t2 <= 1:
		b2 = Trigger.instance()
		$Ghost2.set_color(c2, 1)
	else:
		b2 = Block.instance()
		$Ghost2.set_color(c2, 0)
	
	b1.position.x = 80 * cp.x
	b2.position.y = -80
	
	b1.falling = true
	
	b1.add_child(b2)
	add_child(b1)
	active_piece = b1
	
	b1.set_color(c1)
	b2.set_color(c2)
	
	render_ghosts(b1)


func win():
	"""TODO"""
	game_over = true
	set_process_input(true)
	
#	if lost:
#		return
	
	$Result/Anim.play('Win')
	$Result/Restart/Anim.play('Pulse')
	$Anim.stop()
	
	if active_piece:
		active_piece.get_node('Anim').stop()
		active_piece.get_node('Anim2').stop()
		if active_piece.partner:
			active_piece.partner.get_node('Anim').stop()
		active_piece.set_process_input(false)
	
	if scoreboard:
		var node = get_node(scoreboard)
		var _score = int(node.get_node('Number/Text').text) + 1
		
		node.get_node('Number/Text').text = str(_score)
		# Prevent the scoreboard from flashing the new score before
		# fading in.
		node.get_node('Number').hide()
		node.get_node('Number/Anim').play('Increment')


func lose():
	"""TODO"""
	$Result/Anim.play('Lose')
	$Result/Restart/Anim.play('Pulse')
	set_process_input(true)
	
	$'/root/Queue'.refresh_queue = true
