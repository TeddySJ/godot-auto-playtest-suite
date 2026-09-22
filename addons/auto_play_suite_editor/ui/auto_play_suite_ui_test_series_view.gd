extends AutoPlaySuiteUiView
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
var move_test_left_button : Button
var move_test_right_button : Button

var load_test_button : Button
var new_test_button : Button

var run_current_test_button : Button
var run_all_tests_button : Button
var abort_testing_button : Button

var underlying_dictionary : Dictionary[Button, AutoPlaySuiteTestResource]

var current_selected_index : int = -1
var current_test_series : AutoPlaySuiteTestSeriesResource
var testing_in_progress : bool = false
var dirty_tests : Dictionary[AutoPlaySuiteTestResource, bool]
var series_has_unsaved_changes : bool = false
var confirmation_dialog : ConfirmationDialog

signal signal_on_current_test_series_saved
signal signal_on_test_changed(new_test : AutoPlaySuiteTestResource)
signal signal_on_new_series
signal signal_on_run_current_test_pressed
signal signal_on_run_all_tests_pressed
signal signal_on_abort_testing_pressed

signal signal_on_new_test_button_pressed
signal signal_on_load_test_button_pressed
signal signal_on_before_series_operation

func _ready() -> void:
	if current_test_series == null:
		current_test_series = AutoPlaySuiteTestSeriesResource.new()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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
	base_panel_container.custom_minimum_size = Vector2(custom_minimum_size.x * size_ratio_for_panel, 50) * ed_scale
	add_child(base_panel_container)
	var scroll_container := ScrollContainer.new()
	base_panel_container.add_child(scroll_container)
	hbox_container = HBoxContainer.new()
	scroll_container.add_child(hbox_container)
	
	var run_test_button_start_pos : Vector2 = base_panel_container.position + Vector2(base_panel_container.custom_minimum_size.x, 0)
	
	run_current_test_button = Button.new()
	run_current_test_button.text = "Run Current Test"
	run_current_test_button.position = run_test_button_start_pos + Vector2(10, 10) * ed_scale
	run_current_test_button.pressed.connect(_on_run_current_test_button_pressed)
	add_child(run_current_test_button)
	
	run_all_tests_button = Button.new()
	run_all_tests_button.text = "Run All Tests"
	run_all_tests_button.position = run_test_button_start_pos + Vector2(170, 10) * ed_scale
	run_all_tests_button.pressed.connect(_on_run_all_tests_button_pressed)
	add_child(run_all_tests_button)

	abort_testing_button = Button.new()
	abort_testing_button.text = "Abort Testing"
	abort_testing_button.position = run_all_tests_button.position + Vector2(140, 0) * ed_scale
	abort_testing_button.disabled = true
	abort_testing_button.pressed.connect(_on_abort_testing_button_pressed)
	add_child(abort_testing_button)
	
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
	
	load_test_button = Button.new()
	load_test_button.position = Vector2(-90, 40) * ed_scale
	load_test_button.text = "Load Test"
	add_child(load_test_button)
	load_test_button.pressed.connect(signal_on_load_test_button_pressed.emit)

	new_test_button = Button.new()
	new_test_button.position = load_test_button.position + Vector2(0, 50) * ed_scale
	new_test_button.text = "New Test"
	add_child(new_test_button)
	new_test_button.pressed.connect(signal_on_new_test_button_pressed.emit)
	
	remove_test_button = Button.new()
	remove_test_button.text = "Remove"
	remove_test_button.position = new_test_button.position + Vector2(0, 50) * ed_scale
	remove_test_button.pressed.connect(_remove_test_button_pressed)
	add_child(remove_test_button)

	move_test_left_button = Button.new()
	move_test_left_button.text = "Move Left"
	move_test_left_button.position = remove_test_button.position + Vector2(0, 50) * ed_scale
	move_test_left_button.pressed.connect(_move_selected_test.bind(-1))
	add_child(move_test_left_button)

	move_test_right_button = Button.new()
	move_test_right_button.text = "Move Right"
	move_test_right_button.position = move_test_left_button.position + Vector2(0, 50) * ed_scale
	move_test_right_button.pressed.connect(_move_selected_test.bind(1))
	add_child(move_test_right_button)
	_update_test_order_buttons()

func _new_series_button_pressed(discard_confirmed : bool = false):
	if testing_in_progress:
		return
	signal_on_before_series_operation.emit()
	if !discard_confirmed && has_unsaved_work():
		_show_discard_confirmation(
			"Discard the current series and its unsaved test changes?",
			_new_series_button_pressed.bind(true)
		)
		return
	clear()
	current_selected_index = -1
	_update_test_order_buttons()
	current_file_path = ""
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	_randomize_test_series_name()
	series_has_unsaved_changes = true
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

	if current_test_series.number_of_runs_per_test.size() != current_test_series.paths_to_tests.size():
		ret = false
		err = "Every test in the series must have a run count."
	else:
		for run_count in current_test_series.number_of_runs_per_test:
			if run_count < 1:
				ret = false
				err = "Test run counts must be at least one."
				break
	
	
	if output_error_reason && !ret:
		printerr(err)
	
	return ret

func _save_test_series(path : String = "") -> bool:
	if file_dialog != null:
		return false
	signal_on_before_series_operation.emit()
	
	if !_can_save_series():
		return false
	
	if path == "":
		if current_file_path == "":
			_save_test_series_as()
			return false
		path = current_file_path
	
	current_test_series.take_over_path(path)
	var save_error := ResourceSaver.save(current_test_series, path)
	if save_error != OK:
		printerr("Failed to save test series to '%s': error %d" % [path, save_error])
		return false
	current_file_path = path
	series_has_unsaved_changes = false
	signal_on_current_test_series_saved.emit()
	return true

func _save_test_series_as():
	if file_dialog != null:
		return
	signal_on_before_series_operation.emit()
	if !_can_save_series():
		return
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.show()
	file_dialog.add_filter("*.testseries.tres", "Test Series Resource")
	_set_file_dialog_size_and_position()
	file_dialog.canceled.connect(_file_dialog_canceled)
	file_dialog.file_selected.connect(_save_file_chosen)

func _save_file_chosen(path : String):
	file_dialog = null
	_save_test_series(path)

func _load_series_button_pressed(discard_confirmed : bool = false):
	if file_dialog != null:
		return
	signal_on_before_series_operation.emit()
	if !discard_confirmed && has_unsaved_work():
		_show_discard_confirmation(
			"Discard the current series and its unsaved test changes before loading another series?",
			_load_series_button_pressed.bind(true)
		)
		return
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE 
	file_dialog.add_filter("*.testseries.tres", "Test Series Resource")
	_set_file_dialog_size_and_position()
	file_dialog.canceled.connect(_file_dialog_canceled)
	file_dialog.file_selected.connect(_load_series)
	file_dialog.show()

func _load_series(path : String):
	file_dialog = null
	var loaded_resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	
	if !(loaded_resource is AutoPlaySuiteTestSeriesResource):
		printerr("The loaded file is not a Test Series Resource")
		return

	var series : AutoPlaySuiteTestSeriesResource = loaded_resource.duplicate(true)
	if _set_current_series(series):
		current_file_path = path

func _file_dialog_canceled():
	file_dialog = null

func _set_file_dialog_size_and_position():
	file_dialog.min_size = Vector2(600, 400) * AutoPlaySuite._get_plugin_singleton().editor_scale
	file_dialog.position = global_position

func _set_current_series(new_series : AutoPlaySuiteTestSeriesResource) -> bool:
	if new_series.paths_to_tests.is_empty():
		printerr("Cannot load an empty test series.")
		return false
	if new_series.number_of_runs_per_test.is_empty():
		for _path in new_series.paths_to_tests:
			new_series.number_of_runs_per_test.append(1)
	elif new_series.number_of_runs_per_test.size() != new_series.paths_to_tests.size():
		printerr("Cannot load a test series whose run counts do not match its tests.")
		return false
	for run_count in new_series.number_of_runs_per_test:
		if run_count < 1:
			printerr("Cannot load a test series with a run count below one.")
			return false

	var loaded_tests : Array[AutoPlaySuiteTestResource] = []
	var seen_test_ids : Dictionary[String, bool] = {}
	for path in new_series.paths_to_tests:
		if path.is_empty():
			printerr("Cannot load a test series containing an unsaved test.")
			return false
		var loaded_resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
		if !(loaded_resource is AutoPlaySuiteTestResource):
			printerr("Could not load test resource from '%s'." % path)
			return false
		var test : AutoPlaySuiteTestResource = loaded_resource.duplicate(true)
		if path.begins_with("uid://"):
			test.test_uid = path
		var test_id := test.test_uid if !test.test_uid.is_empty() else path
		if seen_test_ids.has(test_id):
			printerr("Test series contains the same test more than once: '%s'." % path)
			return false
		seen_test_ids[test_id] = true
		loaded_tests.append(test)

	clear()
	current_selected_index = -1
	current_test_series = new_series
	test_series_name_input.text = current_test_series.test_series_name
	for test in loaded_tests:
		add_test(test, false)
	
	_test_button_pressed(test_button_list[0])
	series_has_unsaved_changes = false
	return true

func _test_series_name_changed(new_text : String):
	current_test_series.test_series_name = new_text
	series_has_unsaved_changes = true

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

func add_test(test_resource : AutoPlaySuiteTestResource, add_to_series : bool = true) -> bool:
	if test_resource.test_uid != "":
		for test : AutoPlaySuiteTestResource in underlying_dictionary.values():
			if test.test_uid == test_resource.test_uid:
				printerr("This test is already a part of the series!")
				return false
	
	var button := Button.new()
	button.text = test_resource.test_name
	test_button_list.append(button)
	
	underlying_dictionary[button] = test_resource
	button.pressed.connect(func():_test_button_pressed(button))
	button.focus_mode = Control.FOCUS_NONE
	hbox_container.add_child(button)
	
	if add_to_series:
		current_test_series.paths_to_tests.append("")
		current_test_series.number_of_runs_per_test.append(1)
		series_has_unsaved_changes = true
		_test_button_pressed(button)
	dirty_tests[test_resource] = add_to_series && test_resource.test_uid.is_empty()
	
	return true

func _on_test_failed_or_passed_test(test : AutoPlaySuiteTestResource, success : bool):
	var index : int = _get_index_of_test(test)
	if index == -1:
		printerr("Could not find the completed test in the current series.")
		return
	if !success:
		test_button_list[index].modulate = Color.RED
	else:
		test_button_list[index].modulate = Color.WHITE
		

func _remove_test_button_pressed(discard_confirmed : bool = false):
	if current_selected_index < 0 || current_selected_index >= test_button_list.size():
		printerr("Cannot remove a test without a valid series selection.")
		return
	signal_on_before_series_operation.emit()
	var selected_test : AutoPlaySuiteTestResource = underlying_dictionary[test_button_list[current_selected_index]]
	if !discard_confirmed && dirty_tests.get(selected_test, false):
		_show_discard_confirmation(
			"Remove this test and discard its unsaved changes?",
			_remove_test_button_pressed.bind(true)
		)
		return

	var removed_index := current_selected_index
	var removed_button := test_button_list[removed_index]
	dirty_tests.erase(selected_test)
	current_test_series.paths_to_tests.remove_at(current_selected_index)
	current_test_series.number_of_runs_per_test.remove_at(current_selected_index)
	underlying_dictionary.erase(removed_button)
	removed_button.queue_free()
	test_button_list.remove_at(current_selected_index)
	series_has_unsaved_changes = true
	
	if test_button_list.size() == 0:
		_on_all_tests_removed()
		return
	
	var next_index := mini(removed_index, test_button_list.size() - 1)
	_test_button_pressed(test_button_list[next_index])

func _on_all_tests_removed():
	current_selected_index = -1
	_update_test_order_buttons()
	signal_on_new_test_button_pressed.emit()

func _move_selected_test(offset : int) -> void:
	if testing_in_progress:
		return
	var destination := current_selected_index + offset
	if current_selected_index < 0 || destination < 0 || destination >= test_button_list.size():
		return

	var moved_button := test_button_list[current_selected_index]
	test_button_list[current_selected_index] = test_button_list[destination]
	test_button_list[destination] = moved_button
	var moved_path := current_test_series.paths_to_tests[current_selected_index]
	current_test_series.paths_to_tests[current_selected_index] = current_test_series.paths_to_tests[destination]
	current_test_series.paths_to_tests[destination] = moved_path
	var moved_run_count := current_test_series.number_of_runs_per_test[current_selected_index]
	current_test_series.number_of_runs_per_test[current_selected_index] = current_test_series.number_of_runs_per_test[destination]
	current_test_series.number_of_runs_per_test[destination] = moved_run_count
	hbox_container.move_child(test_button_list[destination], destination)
	current_selected_index = destination
	series_has_unsaved_changes = true
	_update_test_order_buttons()

func _update_test_order_buttons() -> void:
	if move_test_left_button == null || move_test_right_button == null:
		return
	move_test_left_button.disabled = testing_in_progress || current_selected_index <= 0
	move_test_right_button.disabled = (
		testing_in_progress
		|| current_selected_index < 0
		|| current_selected_index >= test_button_list.size() - 1
	)

func _on_run_current_test_button_pressed():
	if testing_in_progress:
		return
	signal_on_run_current_test_pressed.emit()

func _on_run_all_tests_button_pressed():
	if testing_in_progress:
		return
	signal_on_before_series_operation.emit()
	for uid in current_test_series.paths_to_tests:
		if uid == "":
			printerr("One or more of the tests in the series has not been saved to disk yet!")
			return
	
	if !_save_all_tests_in_series():
		return
	
	signal_on_run_all_tests_pressed.emit()

func _on_abort_testing_button_pressed() -> void:
	if !testing_in_progress || abort_testing_button.disabled:
		return
	abort_testing_button.disabled = true
	signal_on_abort_testing_pressed.emit()

func _save_all_tests_in_series() -> bool:
	var origin_index : int = current_selected_index
	var editor := AutoPlaySuite._get_plugin_singleton()
	for n in test_button_list.size():
		current_selected_index = n
		var test : AutoPlaySuiteTestResource = underlying_dictionary[test_button_list[n]]
		_change_to_test(test)
		if !editor.current_test_view._save_test(_get_test_uid_path(test)):
			_restore_selected_test(origin_index)
			return false

	_restore_selected_test(origin_index)
	return true

func _restore_selected_test(index : int) -> void:
	if index >= 0 && index < test_button_list.size():
		_test_button_pressed(test_button_list[index])

func _get_all_tests_in_order() -> Array[AutoPlaySuiteTestResource]:
	var ret : Array[AutoPlaySuiteTestResource] = []
	for index in test_button_list.size():
		var test : AutoPlaySuiteTestResource = underlying_dictionary[test_button_list[index]]
		for _run_number in current_test_series.number_of_runs_per_test[index]:
			ret.append(test)
	
	return ret

func _get_index_of_test(test_resource : AutoPlaySuiteTestResource) -> int:
	for n in test_button_list.size():
		var candidate : AutoPlaySuiteTestResource = underlying_dictionary[test_button_list[n]]
		if candidate == test_resource:
			return n
		if !test_resource.test_uid.is_empty() && candidate.test_uid == test_resource.test_uid:
			return n
	return -1

func _get_test_uid_path(test_resource : AutoPlaySuiteTestResource) -> String:
	var index : int = _get_index_of_test(test_resource)
	if index == -1:
		printerr("Could not find index of test resource! (_get_test_uid_path)")
		return ""
	var uid = current_test_series.paths_to_tests[index]
	return uid

func _test_button_pressed(button_pressed : Button):
	if testing_in_progress:
		return
	signal_on_before_series_operation.emit()
	for button in test_button_list:
		button.disabled = false
	current_selected_index = test_button_list.find(button_pressed)
	button_pressed.disabled = true
	_update_test_order_buttons()
	_change_to_test(underlying_dictionary[button_pressed])

func _change_to_test(test_resource : AutoPlaySuiteTestResource):
	signal_on_test_changed.emit(test_resource)

func _update_path_to_current_test(new_path : String):
	if current_selected_index < 0 || current_selected_index >= current_test_series.paths_to_tests.size():
		printerr("Cannot update a test path without a valid series selection.")
		return
	if current_test_series.paths_to_tests[current_selected_index] == new_path:
		return
	current_test_series.paths_to_tests[current_selected_index] = new_path
	series_has_unsaved_changes = true

func mark_test_dirty(test : AutoPlaySuiteTestResource) -> void:
	if test != null && underlying_dictionary.values().has(test):
		dirty_tests[test] = true

func mark_action_dirty(action : AutoPlaySuiteActionResource) -> void:
	if action == null:
		return
	for test : AutoPlaySuiteTestResource in underlying_dictionary.values():
		if test.actions.has(action) || test.post_actions.has(action):
			dirty_tests[test] = true
			return

func mark_test_saved(test : AutoPlaySuiteTestResource) -> void:
	if test != null && dirty_tests.has(test):
		dirty_tests[test] = false

func has_unsaved_work() -> bool:
	if series_has_unsaved_changes:
		return true
	for is_dirty in dirty_tests.values():
		if is_dirty:
			return true
	return false

func _show_discard_confirmation(message : String, confirmed_callback : Callable) -> void:
	if is_instance_valid(confirmation_dialog):
		return
	confirmation_dialog = ConfirmationDialog.new()
	confirmation_dialog.dialog_text = message
	confirmation_dialog.confirmed.connect(_on_discard_confirmed.bind(confirmed_callback))
	confirmation_dialog.canceled.connect(_clear_confirmation_dialog)
	add_child(confirmation_dialog)
	confirmation_dialog.popup_centered()

func _on_discard_confirmed(confirmed_callback : Callable) -> void:
	_clear_confirmation_dialog()
	confirmed_callback.call()

func _clear_confirmation_dialog() -> void:
	if is_instance_valid(confirmation_dialog):
		confirmation_dialog.queue_free()
	confirmation_dialog = null

func clear():
	for button in test_button_list:
		button.queue_free()
	test_button_list.clear()
	underlying_dictionary.clear()
	dirty_tests.clear()

func set_testing_in_progress(in_progress : bool) -> void:
	testing_in_progress = in_progress
	test_series_name_input.editable = !in_progress
	new_series_button.disabled = in_progress
	load_series_button.disabled = in_progress
	save_series_button.disabled = in_progress
	save_series_as_button.disabled = in_progress
	remove_test_button.disabled = in_progress
	load_test_button.disabled = in_progress
	new_test_button.disabled = in_progress
	run_current_test_button.disabled = in_progress
	run_all_tests_button.disabled = in_progress
	abort_testing_button.disabled = !in_progress
	for index in test_button_list.size():
		test_button_list[index].disabled = in_progress || index == current_selected_index
	_update_test_order_buttons()
	
