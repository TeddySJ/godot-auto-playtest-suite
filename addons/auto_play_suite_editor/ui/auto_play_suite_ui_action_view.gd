extends AutoPlaySuiteUiView
class_name AutoPlaySuiteUiActionView

var index_pool : int = 0
var backing_dictionary : Dictionary[StringName, int]

var main_panel : Panel
var filter_line_edit : LineEdit
var drop_down : OptionButton
var current_drop_down_option : StringName
var description_label : Label
var run_action_button : Button

var float_var_spinbox : SpinBox
var string_var_line_edit : LineEdit
var timeout_spinbox : SpinBox
var extra_vars_text_edit : TextEdit

var underlying_action : AutoPlaySuiteActionResource = null
var updating_fields : bool = false

signal signal_on_action_id_changed(String)
signal signal_on_action_changed(action_resource : AutoPlaySuiteActionResource)

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
	filter_line_edit.text_changed.connect(_filter_line_edit_changed)
	main_panel.add_child(filter_line_edit)
	
	drop_down = OptionButton.new()
	drop_down.position = Vector2(30, y_offset + 30)* ed_scale
	drop_down.custom_minimum_size.x = 300 * ed_scale
	drop_down.item_selected.connect(_action_id_changed)
	main_panel.add_child(drop_down)

	description_label = Label.new()
	description_label.position = Vector2(30, y_offset + 70) * ed_scale
	description_label.custom_minimum_size = Vector2(300, 45) * ed_scale
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.max_lines_visible = 2
	description_label.clip_text = true
	description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	main_panel.add_child(description_label)
	
	#run_action_button = Button.new()
	#run_action_button.text = "Run"
	#run_action_button.position = Vector2(30, 300) * ed_scale
	#main_panel.add_child(run_action_button)
	
	var float_var_pos := Vector2(30, y_offset + 125) * ed_scale
	
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
	
	var string_var_pos := Vector2(30, y_offset + 185) * ed_scale
	
	label = Label.new()
	label.text = "String Var:"
	label.position = string_var_pos
	main_panel.add_child(label)
	
	string_var_line_edit = LineEdit.new()
	string_var_line_edit.position = string_var_pos + Vector2(100, -4)  * ed_scale
	string_var_line_edit.custom_minimum_size.x = 200 * ed_scale
	string_var_line_edit.text_changed.connect(_string_var_changed)
	main_panel.add_child(string_var_line_edit)

	var timeout_pos := Vector2(30, y_offset + 245) * ed_scale
	label = Label.new()
	label.text = "Timeout:"
	label.tooltip_text = "Maximum wall-clock seconds for this action. Set to 0 to disable the timeout."
	label.position = timeout_pos
	main_panel.add_child(label)

	timeout_spinbox = SpinBox.new()
	timeout_spinbox.min_value = 0
	timeout_spinbox.max_value = 99999999
	timeout_spinbox.step = 0.1
	timeout_spinbox.position = timeout_pos + Vector2(100, -4) * ed_scale
	timeout_spinbox.custom_minimum_size.x = 200 * ed_scale
	timeout_spinbox.tooltip_text = label.tooltip_text
	timeout_spinbox.value_changed.connect(_timeout_changed)
	main_panel.add_child(timeout_spinbox)

	var extra_vars_pos := Vector2(30, y_offset + 305) * ed_scale
	label = Label.new()
	label.text = "Extra Vars:"
	label.tooltip_text = "Additional string arguments, one value per line."
	label.position = extra_vars_pos
	main_panel.add_child(label)

	extra_vars_text_edit = TextEdit.new()
	extra_vars_text_edit.position = extra_vars_pos + Vector2(100, -4) * ed_scale
	extra_vars_text_edit.custom_minimum_size = Vector2(200, 75) * ed_scale
	extra_vars_text_edit.placeholder_text = "One value per line"
	extra_vars_text_edit.tooltip_text = label.tooltip_text
	extra_vars_text_edit.text_changed.connect(_extra_vars_changed)
	main_panel.add_child(extra_vars_text_edit)
	main_panel.custom_minimum_size.y = 445 * ed_scale

func _add_drop_down_item(_name : StringName):
	if backing_dictionary.has(_name):
		return
	drop_down.add_item(_name, index_pool)
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
	
	var filters := filter_text.split(" ")
	
	var all_names = backing_dictionary.keys()
	var matched_names : Array[StringName] = []
	for n in all_names.size():
		var str : StringName = all_names[n]
		var has_all : bool = true
		for filter in filters:
			if filter != "" && !str.containsn(filter):
				has_all = false
		if has_all:
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

func _filter_line_edit_changed(text : String):
	_filter_drop_down(text)
	#TODO: This should really show the drop down list, but I think it's not possible to show it while retaining focus: 
	#      I need to rewrite the dropdown as something else! Probably with an ItemList that hides on pick

func _action_id_changed(index : int):
	var selected_action_id := StringName(drop_down.get_item_text(index))
	underlying_action.action_id = selected_action_id
	current_drop_down_option = selected_action_id
	_update_description()
	signal_on_action_id_changed.emit(selected_action_id)
	underlying_action.float_var = 0
	underlying_action.string_var = ""
	underlying_action.extra_vars.clear()
	updating_fields = true
	float_var_spinbox.set_value_no_signal(0)
	string_var_line_edit.text = ""
	extra_vars_text_edit.text = ""
	updating_fields = false
	signal_on_action_changed.emit(underlying_action)

func _string_var_changed(new_text : String):
	if updating_fields:
		return
	underlying_action.string_var = new_text
	signal_on_action_changed.emit(underlying_action)

func _float_var_changed(new_value : float):
	if updating_fields:
		return
	underlying_action.float_var = new_value
	signal_on_action_changed.emit(underlying_action)

func _timeout_changed(new_value : float):
	if updating_fields:
		return
	underlying_action.timeout_seconds = new_value
	signal_on_action_changed.emit(underlying_action)

func _extra_vars_changed() -> void:
	if updating_fields:
		return
	var new_values : Array[String] = []
	if !extra_vars_text_edit.text.is_empty():
		for value in extra_vars_text_edit.text.split("\n", true):
			new_values.append(value)
	underlying_action.extra_vars = new_values
	signal_on_action_changed.emit(underlying_action)

func _set_action(action_to_set : AutoPlaySuiteActionResource):
	_commit_pending_float_edit()
		
	underlying_action = action_to_set
	if !backing_dictionary.has(underlying_action.action_id):
		_add_drop_down_item(underlying_action.action_id)
	current_drop_down_option = underlying_action.action_id
	_filter_drop_down(filter_line_edit.text)
	_update_description()
	_update_text_fields()

func commit_pending_edits() -> void:
	_commit_pending_float_edit()

func _commit_pending_float_edit() -> bool:
	if underlying_action == null || float_var_spinbox.get_line_edit().text.is_empty():
		return false
	var text_value := float(float_var_spinbox.get_line_edit().text)
	if text_value == underlying_action.float_var:
		return false
	float_var_spinbox.set_value_no_signal(text_value)
	float_var_spinbox.get_line_edit().text = ""
	underlying_action.float_var = text_value
	signal_on_action_changed.emit(underlying_action)
	return true

func _update_description() -> void:
	var definition := AutoPlaySuiteActionLibrary.get_action(current_drop_down_option)
	if definition != null:
		description_label.text = definition.description
	elif current_drop_down_option == &"[UNSET]":
		description_label.text = "Select an action to configure."
	else:
		description_label.text = "This action is not currently registered."
	description_label.tooltip_text = description_label.text
	drop_down.tooltip_text = description_label.text

func _update_text_fields():
	updating_fields = true
	var drop_down_id : int = backing_dictionary[underlying_action.action_id]
	drop_down.select(drop_down.get_item_index(drop_down_id))
	string_var_line_edit.text = underlying_action.string_var
	float_var_spinbox.value = underlying_action.float_var
	timeout_spinbox.value = underlying_action.timeout_seconds
	extra_vars_text_edit.text = "\n".join(underlying_action.extra_vars)
	updating_fields = false

func _select_in_drop_down(item_name : StringName):
	var drop_down_id : int = backing_dictionary[item_name]
	var ind = drop_down.get_item_index(drop_down_id)
	drop_down.select(ind)

func set_testing_in_progress(in_progress : bool) -> void:
	filter_line_edit.editable = !in_progress
	drop_down.disabled = in_progress
	float_var_spinbox.editable = !in_progress
	string_var_line_edit.editable = !in_progress
	timeout_spinbox.editable = !in_progress
	extra_vars_text_edit.editable = !in_progress
	
