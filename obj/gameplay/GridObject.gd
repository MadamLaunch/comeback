extends Node2D
class_name GridObject


const SIZE = 80
const HALF_SIZE = 40
const WIDTH = 7
const HEIGHT = 13

export var snap_on_ready = true


func _ready():
	if snap_on_ready:
		point()


func point(snap=false):
	var p = Vector2(
		int(round(position.x / SIZE)),
		int(round(position.y / SIZE)))
	if snap: position = p * SIZE
	return p


func key():
	var p = point()
	return str(p.x) + ',' + str(p.y)


func set(x, y):
	position = Vector2(x, y) * SIZE
	return Vector2(x, y)


func set_x(n):
	return set(n, point(true).y)


func set_y(n):
	return set(point(true).x, n)


func set_v(v):
	return set(v.x, v.y)


func move(x, y):
	var p = point() + Vector2(x, y)
	set_v(p)
	return p
