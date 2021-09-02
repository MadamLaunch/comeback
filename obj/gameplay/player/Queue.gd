extends Node


const DIAMOND_SPACING = 25

var queue = []

var refresh_queue = false


func get(i):
	"""Return an entry from queue-list, guaranteeing population."""
	while i >= queue.size():
		populate()
	
	return queue[i]


func populate():
	"""Add another cycle of random Block/Trigger-pairs."""
	randomize()
	# Cycles will always end with a Diamond, so stop looping early.
	#warning-ignore:unused_variable
	for j in range(DIAMOND_SPACING - 1):
		# Pieces have a 20% chance of being a trigger.
		# Block = 0; Trigger = 1
		var t1 = int((randi() % 5) == 0)
		var t2 = int((randi() % 5) == 0)
		
		var c1 = randi() % 5
		var c2 = randi() % 5
		
		queue.append([[c1, t1], [c2, t2]])
	
	# Top off the cycle with a Diamond.
	queue.append([[-1, 2]])


func clear():
	"""A shortcut to `queue.clear()`."""
	queue.clear()
