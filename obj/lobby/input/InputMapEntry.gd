extends HBoxContainer


export(String) var action_label
export(String) var action


func _ready():
	$Action.text = action_label
