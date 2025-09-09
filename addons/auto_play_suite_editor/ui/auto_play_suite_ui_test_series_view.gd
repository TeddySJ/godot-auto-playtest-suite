extends Control
class_name AutoPlaySuiteUiTestSeriesView

var file_dialog : FileDialog
var current_file_path : String

var test_series_name_input : LineEdit

var base_panel_container : PanelContainer
var hbox_container : HBoxContainer
var test_button_list : Array[Button]

var new_series_button : Button
var load_series_button : Button
var save_series_button : Button
var save_series_as_button : Button
var remove_test_button : Button

var underlying_dictionary : Dictionary[Button, AutoPlaySuiteTestResource]

var current_selected_index : int = -1
var current_test_series : AutoPlaySuiteTestSeriesResource

signal signal_on_current_test_series_saved
signal signal_on_test_changed(new_test : AutoPlaySuiteTestResource)
signal signal_on_new_series

func _ready() -> void:
	if current_test_series == null:
		current_test_series = AutoPlaySuiteTestSeriesResource.new()
	
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	test_series_name_input = LineEdit.new()
	test_series_name_input.position = Vector2(20, 0) * ed_scale
	test_series_name_input.custom_minimum_size.x = 300 * ed_scale
	test_series_name_input.text_changed.connect(_test_series_name_changed)
	add_child(test_series_name_input)
	
	var test_series_name_label = Label.new()
	test_series_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	test_series_name_label.text = "Series Name:"
	test_series_name_label.position = test_series_name_input.position + Vector2(-210, 5)  * ed_scale
	test_series_name_label.custom_minimum_size.x = 200 * ed_scale
	add_child(test_series_name_label)
	
	_randomize_test_series_name()
	
	var size_ratio_for_panel : float = 0.6
	var size_ratio_for_save_buttons : float = 1 - size_ratio_for_panel
	
	base_panel_container = PanelContainer.new()
	base_panel_container.position = Vector2(0, 35) * ed_scale
	base_panel_container.custom_minimum_size = Vector2(custom_minimum_size.x * size_ratio_for_panel, 50)
	add_child(base_panel_container)
	var scroll_container := ScrollContainer.new()
	base_panel_container.add_child(scroll_container)
	hbox_container = HBoxContainer.new()
	scroll_container.add_child(hbox_container)
	
	var button_start_pos : Vector2 = test_series_name_input.position + Vector2(test_series_name_input.custom_minimum_size.x, 0)
	
	new_series_button = Button.new()
	new_series_button.text = "New Series"
	new_series_button.position = button_start_pos + Vector2(10, 0) * ed_scale
	new_series_button.pressed.connect(_new_series_button_pressed)
	add_child(new_series_button)
	
	load_series_button = Button.new()
	load_series_button.text = "Load Series"
	load_series_button.position = button_start_pos + Vector2(120, 0) * ed_scale
	load_series_button.pressed.connect(_load_series_button_pressed)
	add_child(load_series_button)

	save_series_button = Button.new()
	save_series_button.text = "Save Series"
	save_series_button.position = button_start_pos + Vector2(230, 0) * ed_scale
	save_series_button.pressed.connect(_save_test_series)
	add_child(save_series_button)

	save_series_as_button = Button.new()
	save_series_as_button.text = "Save Series As"
	save_series_as_button.position = button_start_pos + Vector2(340, 0) * ed_scale
	save_series_as_button.pressed.connect(_save_test_series_as)
	add_child(save_series_as_button)
	
	remove_test_button = Button.new()
	remove_test_button.text = "Remove Test"
	remove_test_button.position = button_start_pos + Vector2(470, 0) * ed_scale
	remove_test_button.pressed.connect(_remove_test_button_pressed)
	add_child(remove_test_button)

func _new_series_button_pressed():
	clear()
	_randomize_test_series_name()
	current_selected_index = -1
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	signal_on_new_series.emit()

func _can_save_series(output_error_reason : bool = true) -> bool:
	var err: String = ""
	var ret: bool = true
	
	if test_button_list.size() == 0:
		ret = false
		err = "Can't save an empty series!"
	
	for s in current_test_series.paths_to_tests:
		if s == "":
			ret = false
			err = "All tests must be saved to disk before the series can be saved!"
			break
	
	
	if output_error_reason && !ret:
		printerr(err)
	
	return ret

func _save_test_series(path : String = ""):
	if file_dialog != null:
		return
	
	if !_can_save_series():
		return
	
	if path == "":
		if current_file_path == "":
			_save_test_series_as()
			return
		path = current_file_path
	
	current_file_path = path
	
	print(current_test_series.paths_to_tests.size())
	
	current_test_series.take_over_path(path)
	ResourceSaver.save(current_test_series, path)
	signal_on_current_test_series_saved.emit()

func _save_test_series_as():
	if file_dialog != null:
		return
	if !_can_save_series():
		return
	
	var file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.show()
	file_dialog.add_filter("*.testseries.tres", "Test Series Resource")
	file_dialog.file_selected.connect(_save_file_chosen)

func _save_file_chosen(path : String):
	file_dialog = null
	_save_test_series(path)

func _load_series_button_pressed():
	if file_dialog != null:
		return
	
	var file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE 
	file_dialog.add_filter("*.testseries.tres", "Test Series Resource")
	file_dialog.file_selected.connect(_load_series)
	file_dialog.show()

func _load_series(path : String):
	file_dialog = null
	var series : AutoPlaySuiteTestSeriesResource = load(path)
	
	if series == null:
		printerr("The loaded file is not a Test Series Resource")
		return

	current_file_path = path
	_set_current_series(series.duplicate(true))

func _set_current_series(new_series : AutoPlaySuiteTestSeriesResource):
	clear()
	current_test_series = new_series
	test_series_name_input.text = current_test_series.test_series_name
	print(current_test_series.paths_to_tests.size())
	for path in current_test_series.paths_to_tests:
		var res : AutoPlaySuiteTestResource = load(path)
		if res == null:
			printerr("Loaded Test in Test Series was not a test?!")
		else:
			add_test(res, false)
	
	if test_button_list.size() == 0:
		return
	
	_test_button_pressed(test_button_list[0])

func _test_series_name_changed(new_text : String):
	current_test_series.test_series_name = new_text

func _randomize_test_series_name():
	var rand_name : String = "Series #"
	for n in 4:
		rand_name += str(randi_range(0, 9))
	test_series_name_input.text = rand_name
	current_test_series.test_series_name = rand_name

func current_test_name_changed(new_name : String):
	for button in test_button_list:
		if button.disabled:
			button.text = new_name

func add_test(test_resource : AutoPlaySuiteTestResource, add_to_series : bool = true):
	var button := Button.new()
	button.text = test_resource.test_name
	test_button_list.append(button)
	
	underlying_dictionary[button] = test_resource
	button.pressed.connect(func():_test_button_pressed(button))
	button.focus_mode = Control.FOCUS_NONE
	hbox_container.add_child(button)
	
	if add_to_series:
		current_test_series.paths_to_tests.append("")
		_test_button_pressed(button)

func _remove_test_button_pressed():
	current_test_series.paths_to_tests.remove_at(current_selected_index)
	test_button_list[current_selected_index].queue_free()
	test_button_list.remove_at(current_selected_index)
	
	if current_selected_index > 0:
		current_selected_index -= 1
	
	if test_button_list.size() == 0:
		_on_all_tests_removed()
		return
	
	_test_button_pressed(test_button_list[0])

func _on_all_tests_removed():
	print("All tests removed!")

func _test_button_pressed(button_pressed : Button):
	for button in test_button_list:
		button.disabled = false
	current_selected_index = test_button_list.find(button_pressed)
	button_pressed.disabled = true
	signal_on_test_changed.emit(underlying_dictionary[button_pressed])

func _update_path_to_current_test(new_path : String):
	current_test_series.paths_to_tests[current_selected_index] = new_path


func clear():
	for button in test_button_list:
		button.queue_free()
	test_button_list.clear()
	underlying_dictionary.clear()
	
