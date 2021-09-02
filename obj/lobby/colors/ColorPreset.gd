extends Object
class_name ColorPreset


var name : String
var data : Color


func to_dict():
	var d = {}
	d['name'] = name
	d['data'] = data.to_html(false)
	return d
