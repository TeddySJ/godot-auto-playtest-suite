extends AutoPlaySuiteUiView
class_name AutoPlaySuiteUiActionView

static var index_pool : int = 0
var backing_dictionary : Dictionary[StringName, int]

var main_panel : Panel
var filter_line_edit : LineEdit
var drop_down : OptionButton
var current_drop_down_option : StringName
var run_action_button : Button

var float_var_spinbox : SpinBox
var string_var_line_edit : LineEdit
# TODO: Add functionality for the array of strings, possibly via a dropdown as an interface (with add new and remove as buttons)

var underlying_action : AutoPlaySuiteActionResource = null

signal signal_on_action_id_changed(String)
signal signal_on_action_changed

func _ready() -> void:
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	main_panel = Panel.new()
	main_panel.custom_minimum_size = Vector2(400, 300) * ed_scale
	add_child(main_panel)
	
	var y_offset : float = 30
	
	filter_line_edit = LineEdit.new()
	filter_line_edit.position = Vector2(30, y_offset + 0)* ed_scale
	filter_line_edit.custom_minimum_size.x = 300 * ed_scale
	filter_line_edit.text_changed.connect(_filter_drop_down)
	main_panel.add_child(filter_line_edit)
	
	drop_down = OptionButton.new()
	drop_down.position = Vector2(30, y_offset + 30)* ed_scale
	drop_down.custom_minimum_size.x = 300 * ed_scale
	drop_down.item_selected.connect(_action_id_changed)
	main_panel.add_child(drop_down)
	
	#run_action_button = Button.new()
	#run_action_button.text = "Run"
	#run_action_button.position = Vector2(30, 300) * ed_scale
	#main_panel.add_child(run_action_button)
	
	var float_var_pos := Vector2(30, y_offset + 80) * ed_scale
	
	var label := Label.new()
	label.text = "Float Var:"
	label.position = float_var_pos
	main_panel.add_child(label)
	
	float_var_spinbox = SpinBox.new()
	float_var_spinbox.min_value = -99999999
	float_var_spinbox.max_value = 99999999
	float_var_spinbox.step = 0.01
	float_var_spinbox.position = float_var_pos + Vector2(100, -4)  * ed_scale
	float_var_spinbox.custom_minimum_size.x = 200 * ed_scale
	float_var_spinbox.value_changed.connect(_float_var_changed)
	main_panel.add_child(float_var_spinbox)
	
	var string_var_pos := Vector2(30,y_offset +  140) * ed_scale
	
	label = Label.new()
	label.text = "String Var:"
	label.position = string_var_pos
	main_panel.add_child(label)
	
	string_var_line_edit = LineEdit.new()
	string_var_line_edit.position = string_var_pos + Vector2(100, -4)  * ed_scale
	string_var_line_edit.custom_minimum_size.x = 200 * ed_scale
	string_var_line_edit.text_changed.connect(_string_var_changed)
	main_panel.add_child(string_var_line_edit)

func _add_drop_down_item(_name : StringName):
	drop_down.add_item(_name)
	backing_dictionary[_name] = index_pool
	index_pool += 1

func _fill_drop_down(names : Array[StringName]):
	for _name in names:
		_add_drop_down_item(_name)

func _filter_drop_down(filter_text : String):
	if filter_text == "":
		drop_down.clear()
		for entry in backing_dictionary.keys():
			drop_down.add_item(entry, backing_dictionary[entry])
		#drop_down.text = current_drop_down_option
		_select_in_drop_down(current_drop_down_option)
		return
	
	var all_names = backing_dictionary.keys()
	var matched_names : Array[StringName] = []
	for n in all_names.size():
		var str : StringName = all_names[n]
		if str.contains(filter_text):
			matched_names.append(str)
	drop_down.clear()
	var added_current: bool = false
	for entry in matched_names:
		drop_down.add_item(entry, backing_dictionary[entry])
		if entry == current_drop_down_option:
			added_current = true
	if !added_current:
		drop_down.add_item(current_drop_down_option, backing_dictionary[current_drop_down_option])
	#drop_down.text = current_drop_down_option
	_select_in_drop_down(current_drop_down_option)
	

func _action_id_changed(index : int):
	underlying_action.action_id = drop_down.text
	current_drop_down_option = drop_down.text
	signal_on_action_id_changed.emit(drop_down.text)
	float_var_spinbox.value = 0
	string_var_line_edit.text = ""
	signal_on_action_changed.emit()

func _string_var_changed(new_text : String):
	underlying_action.string_var = new_text
	signal_on_action_changed.emit()

func _float_var_changed(new_value : float):
	underlying_action.float_var = new_value
	signal_on_action_changed.emit()

func _set_action(action_to_set : AutoPlaySuiteActionResource):
	if underlying_action != null:
		if float_var_spinbox.get_line_edit().text != "":
			var text_value = float(float_var_spinbox.get_line_edit().text)
			if text_value != float_var_spinbox.value:
				float_var_spinbox.set_value_no_signal(float(float_var_spinbox.get_line_edit().text))
				float_var_spinbox.get_line_edit().text = ""
				underlying_action.float_var = text_value
		
	underlying_action = action_to_set
	current_drop_down_option = underlying_action.action_id
	_filter_drop_down(filter_line_edit.text)
	_update_text_fields()

func _update_text_fields():
	var drop_down_id : int = backing_dictionary[underlying_action.action_id]
	drop_down.select(drop_down.get_item_index(drop_down_id))
	string_var_line_edit.text = underlying_action.string_var
	float_var_spinbox.value = underlying_action.float_var

func _select_in_drop_down(item_name : StringName):
	var drop_down_id : int = backing_dictionary[item_name]
	var ind = drop_down.get_item_index(drop_down_id)
	print(drop_down_id, ":", ind)
	drop_down.select(ind)
	
