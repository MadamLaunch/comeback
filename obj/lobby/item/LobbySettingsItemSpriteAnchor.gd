extends Node2D


func _process(_delta):
	if not visible:
		set_process(false)
		return
	
	match $'..'.name:
		'L':
			position.x = $'..'.rect_size.x - 10
		'R':
			position.x = 10
	position.y =  $'..'.rect_size.y * .5
