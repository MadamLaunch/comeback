extends 'res://obj/gameplay/GridObject.gd'


var number = '1'


func _input(event):
	if event.is_action_pressed(number + '_cursor_left'):
		if point().x > 0:
			move(-1, 0)
		#	$Move1.play()
	if event.is_action_pressed(number + '_cursor_right'):
		if point().x < WIDTH - 1:
			move(1, 0)
		#	$Move1.play()
	if event.is_action_pressed(number + '_cursor_slam_left'):
		if point().x > 0:
			set(0, 0)
			$Anim.play('Flash L')
	if event.is_action_pressed(number + '_cursor_slam_right'):
		if point().x < WIDTH - 1:
			set(WIDTH - 1, 0)
			$Anim.play('Flash R')
