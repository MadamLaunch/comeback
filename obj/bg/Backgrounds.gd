extends Node2D


var scenes = []


func _ready():
	var bg = Directory.new()
	bg.open('res://bg')
	bg.list_dir_begin()
	var file = bg.get_next()
	while (file != ''):
		var ext = file.substr(file.length() - 4, file.length())
		if ext == 'tscn' or ext == 'scn':
			scenes.append(file)
		file = bg.get_next()


var s1 = ''
var s2 = ''
var loader


func new_bg():
	randomize()
	var s = scenes[randi() % scenes.size()]
	while s == s1 or s == s2:
		s = scenes[randi() % scenes.size()]
	if current_layer == 2:
		s2 = s
	else:
		s1 = s
	loader = ResourceLoader.load_interactive('res://bg/' + s)
	set_process(true)


var current_layer = 0


func _process(delta):
	delta -= 1
	if loader == null:
		set_process(false)
		return
	
	var err = loader.poll()
	if err == ERR_FILE_EOF: # load finished
		var resource = loader.get_resource()
		loader = null
		$Anim.playback_speed = 1.0
		if current_layer == 1:
			if $BG2.get_child_count():
				$BG2.get_child(0).free()
			$BG2.add_child(resource.instance())
			$Anim.play('Swap1')
			current_layer = 2
		else:
			if $BG1.get_child_count():
				$BG1.get_child(0).free()
			$BG1.add_child(resource.instance())
			if current_layer:
				$Anim.play('Swap2')
			else:
				$Anim.play('Swap0')
			current_layer = 1
	elif err != OK:
		print(loader)
		loader = null
