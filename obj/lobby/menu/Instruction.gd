extends Control


func _ready():
	add_to_group(str($'..'.get_instance_id()) + ' instruction')


func display(value : String):
	show()
	$Label.text = value
