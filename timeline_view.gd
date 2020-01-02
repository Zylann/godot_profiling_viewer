extends Control

const LANE_CAPACITY = 16
const CHUNK_DURATION = 0.5

const EVENT_PUSH = 0
const EVENT_POP = 1

signal hovered_time(time)

export(Gradient) var lane_gradient

var _chunked_lanes = null
var _string_dict = {}
var _time_width = 2.0
var _time_offset = 0.0
var _thickness_threshold = 0.5
var _end_time = 0.0


func set_timeline_data(data):
	_string_dict = data.string_dict
	var events = data.events
	_simplify_descriptions(_string_dict)
	var lanes = _build_lanes(events)
	if len(lanes) > 0:
		var last_item = lanes[0][-1]
		_end_time = last_item[0] + last_item[1]
		_time_offset = lanes[0][0][0] - _time_width * 0.2
		_chunked_lanes = _chunkify_lanes(lanes, CHUNK_DURATION)
	else:
		print("There are no lanes")
	update()


func set_thickness_threshold(t):
	_thickness_threshold = t
	update()


func _gui_input(event):
	
	if event is InputEventMouseButton:
		if event.pressed:
			var zoom_factor = 1.25
			var mpos = event.position
			match event.button_index:
				BUTTON_WHEEL_UP:
					_add_zoom(1.0 / zoom_factor, mpos)
				BUTTON_WHEEL_DOWN:
					_add_zoom(zoom_factor, mpos)
	
	elif event is InputEventMouseMotion:
		if (event.button_mask & BUTTON_MASK_MIDDLE) != 0:
			var seconds_per_pixel = _time_width / rect_size.x
			_time_offset -= event.relative.x * seconds_per_pixel
			update()
			#_print_window()
		emit_signal("hovered_time", _x_to_time(event.position.x))


func _x_to_time(x):
	return _time_offset + _time_width * x / rect_size.x


func _set_time_width(tw):
	_time_width = tw
	update()


func _add_zoom(factor, mpos):
	var d = mpos.x / rect_size.x
	var prev_width = _time_width
	_set_time_width(_time_width * factor)
	_time_offset -= d * (_time_width - prev_width)
	#_print_window()


func _print_window():
	print("Time offset: ", _time_offset, ", width: ", _time_width)


func _draw():
	if _chunked_lanes == null:
		return
	
	var lane_height = 32
	var lane_separation = 1
	var time_scale = rect_size.x / _time_width
	var font = get_font("font")
	var font_offset = Vector2(8, 8 + font.ascent)
	var force_draw_text = Input.is_key_pressed(KEY_T)
		
	var begin_chunk = int(floor(_time_offset / CHUNK_DURATION))
	var end_chunk = int(ceil((_time_offset + _time_width) / CHUNK_DURATION))
	if begin_chunk < 0:
		begin_chunk = 0
	if end_chunk < 0:
		end_chunk = 0
	var lane_index = 0
	var pos = Vector2()

	for lane in _chunked_lanes:
		
		var lane_color = lane_gradient.interpolate(lane_index / float(len(_chunked_lanes)))
		var last_item = null
		
		for chunk_index in range(begin_chunk, end_chunk):
			if chunk_index >= len(lane):
				break
			var chunk = lane[chunk_index]
			
			for item in chunk:
				
				if item == last_item:
					continue
				
				var time = item[0]
				var rtime = time - _time_offset
				var duration = item[1]
				
				if rtime + duration < 0:
					continue
				if rtime > _time_width:
					break
				
				var w = duration * time_scale
				if w < _thickness_threshold:
					continue
				
				pos.x = time_scale * rtime
				w = max(w - 1, 1)
				
				draw_rect(Rect2(pos, Vector2(w, lane_height)), lane_color)
				
				if w > 50 or force_draw_text:
					var s = _string_dict[item[2]]
					var ss = font.get_string_size(s)
					if ss.x + font_offset.x < w or force_draw_text:
						draw_string(font, (pos + font_offset + Vector2(1, 1)).floor(), s, Color(0,0,0))
						draw_string(font, (pos + font_offset).floor(), s)
				
				last_item = item
		
		lane_index += 1
		pos.y += lane_height + lane_separation
	
	var end_x = (_end_time - _time_offset) * time_scale
	draw_rect(Rect2(end_x, 0, 2, rect_size.y), Color(0.5, 0, 0))


static func _simplify_descriptions(strings_dict):
	var keys = []
	var values = []
	for k in strings_dict:
		keys.append(k)
		values.append(strings_dict[k])
	var common = _find_common_base(values)
	print("Common description: ", common)
	if len(common) == 0:
		return
	strings_dict.clear()
	for i in len(values):
		strings_dict[keys[i]] = values[i].right(len(common))


static func _find_common_base(strings):
	var common = _get_longest_string(strings)
	var valid = false
	while not valid:
		valid = true
		for s in strings:
			if not s.begins_with(common):
				valid = false
				common = common.substr(0, len(common) - 1)
				if len(common) == 0:
					return ""
				break
	return common


static func _get_longest_string(strings):
	var longest = ""
	for s in strings:
		if len(s) > len(longest):
			longest = s
	return longest


static func _chunkify_lanes(lanes, duration):
	var chunked_lanes = []
	
	for i in len(lanes):
		print("Chunking lane ", i)
		
		var lane = lanes[i]
		var chunks = []
		
		for item in lane:
			var item_time = item[0]
			var item_duration = item[1]
			
			while len(chunks) * duration < item_time + item_duration:
				chunks.append([])
			
			var begin_chunk = int(floor(item_time / duration))
			var end_chunk = int(ceil((item_time + item_duration) / duration))
			
			for ci in range(begin_chunk, end_chunk):
				var chunk = chunks[ci]
				chunk.append(item)
		
		chunked_lanes.append(chunks)
	
	return chunked_lanes

	
static func _build_lanes(events):
	print("Building lanes")

	var lanes = []
	var lane_index = -1
	var event_index = 0
	
	print("Building lanes for ", len(events), " events")
	
	while event_index < len(events):
		var e = events[event_index]
		var time = e[0]
		var type = e[1]
		var desc_index = e[2]
		
		if type == EVENT_PUSH:
			lane_index += 1
			assert(lane_index >= 0)
			assert(lane_index < LANE_CAPACITY)
			var item = [
				time,
				-1,
				desc_index
			]
			if lane_index >= len(lanes):
				lanes.append([])
			lanes[lane_index].append(item)
		
		elif type == EVENT_POP:
#			if lane_index < 0:
#				event_index += 1
#				continue
			assert(lane_index >= 0)
			var item = lanes[lane_index][-1]
			item[1] = time - item[0]
			lane_index -= 1
			
		else:
			assert(false)
		
		event_index += 1
	
	return lanes

