extends Node2D


const Block = preload('res://obj/gameplay/block/Block.tscn')
const Trigger = preload('res://obj/gameplay/block/trigger/Trigger.tscn')
const Diamond = preload('res://obj/gameplay/block/diamond/Diamond.tscn')

const DIAMOND_SPACING = 25

export(NodePath) var source
export(NodePath) var countdown

export var read_input = false
export var container = false

var count = 0


func _ready():
	# REMINDER: if these conversions haven't occurred, then someone
	# left `auto_start` set to true in BlockContainer.
	if source:
		source = get_node(source)
	if countdown:
		countdown = get_node(countdown)
	
	#if not read_input and not container:
	#	pull()
	
	set_process_input(read_input)


func _input(event):
	if event.is_action_pressed('1_test'):
		pop().queue_free()
		#clear()


func pop():
	"""Return game piece from source; meant for use by containers."""
	if container:
		if (source and not source.get_child_count()):
			clear()
			$Queue.get_child(0).count = 0
			for child in $Queue.get_children():
				if child.name[0] != 'p':
					break
				child.pull()
		#	$Queue/p4.count = 0
		#	$Queue/p4.pull()
		#	$Queue/p3.pull()
		#	$Queue/p2.pull()
		#	$Queue/p1.pull()
	if source:
		var c = source.get_child(0)
		source.remove_child(c)
		
		# Recursively increment entire line of Previews.
		source.pull()
		
		return c


func pull():
	"""Shift/reference/create game piece from source to self."""
	# Keep logistics for testing, if there's no Queue.
	var spawn_diamond = false
	if countdown:
		var t = int(countdown.text) - 1
		if t == 0:
			if has_node('/root/Queue'):
				t = $'/root/Queue'.DIAMOND_SPACING
			else:
				# The backmost Preview will have to spawn a Diamond.
				spawn_diamond = true
				t = DIAMOND_SPACING
		countdown.bbcode_text = '[right]' + str(t) + ' [/right]'
	
	# Change parentage from another Preview object.
	if source:
		var c = source.get_child(0)
		source.remove_child(c)
		add_child(c)
		c.position = Vector2(0, 0)
		
		source.pull()
	# Create game piece objects according to singleton Queue.
	elif has_node('/root/Queue'):
		var q = $'/root/Queue'.get(count)
		if q.size() == 1:
			add_child(Diamond.instance())
		else:
			var b1
			if q[0][1]:
				b1 = Trigger.instance()
			else:
				b1 = Block.instance()
			
			var b2
			if q[1][1]:
				b2 = Trigger.instance()
			else:
				b2 = Block.instance()
			
			b2.position.y = -80
			b1.add_child(b2)
			add_child(b1)
			b1.set_color(q[0][0])
			b2.set_color(q[1][0])
		count += 1
	# If there's no source or Queue, fall back to pure randomness.
	# Provide a Diamond if the fallback code says so.
	elif spawn_diamond:
		var d = Diamond.instance()
		add_child(d)
	# Generate a random pair of Blocks/Triggers.
	else:
		# Pieces have a 20% chance of being a trigger.
		var t1 = randi() % 5
		var t2 = randi() % 5
		
		var c1 = randi() % 5
		var c2 = randi() % 5
		
		var b1
		if t1 <= 1:
			b1 = Trigger.instance()
		else:
			b1 = Block.instance()
		var b2
		if t2 <= 1:
			b2 = Trigger.instance()
		else:
			b2 = Block.instance()
		
		b2.position.y = -80
		
		b1.add_child(b2)
		add_child(b1)
		b1.set_color(c1)
		b2.set_color(c2)


func clear():
	"""Free game piece from self and source; clear Queue singleton."""
	if not container and get_child_count():
		# `free()` is used to allow `get_child_count()` to immediately
		# read 0 in full repopulations triggered by rematches.
		get_child(0).free()
	
	if source:
		# Recursively wipe entire line of Previews.
		source.clear()
	
	if countdown:
		if countdown is NodePath:
			countdown = get_node(countdown)
		
		if has_node('/root/Queue'):
			countdown.bbcode_text = \
				'[right]' + str($'/root/Queue'.DIAMOND_SPACING) + ' [/right]'
		else:
			countdown.bbcode_text = \
				'[right]' + str(DIAMOND_SPACING) + ' [/right]'
