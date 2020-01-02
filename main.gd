extends Control

onready var _status_label = get_node("StatusBar/HBoxContainer/StatusLabel")
onready var _main_view = get_node("Main")


func _ready():
	var path = "D:/PROJETS/INFO/GODOT/Games/VoxelGame/VoxelDemo/project/_profiling_data.bin"
	var res = load_profiler_data(path)
	_main_view.set_timeline_data(res)


static func load_profiler_data(fpath):
	print("Loading profiler data")
	var f = File.new()
	var err = f.open(fpath, File.READ)
	if err != OK:
		printerr("Could not open ", fpath, ", error ", err)
		return null
	var string_dict_count = f.get_16()
	print("String dict count: ", string_dict_count)
	var string_dict = {}
	for i in string_dict_count:
		var k = f.get_16()
		var s = f.get_pascal_string()
		#print("[", k, "]: ", s)
		string_dict[k] = s
	var events = []
	while not f.eof_reached():
		var time = f.get_32() / 1000000.0
		var type = f.get_8()
		var desc_index = f.get_16()
		#print("Event ", time, ", ", type, ", ", desc_index)
		events.append([time, type, desc_index])
	f.close()
	return {
		"string_dict": string_dict,
		"events": events
	}


func _on_Main_hovered_time(time):
	_status_label.text = str(time)


func _on_PreciseCheckBox_toggled(button_pressed):
	if button_pressed:
		_main_view.set_thickness_threshold(0.01)
	else:
		_main_view.set_thickness_threshold(0.5)
