@tool
extends Control
class_name AutoPlaySuite

static var Singleton : AutoPlaySuite:
	get:
		return _get_plugin_singleton()

enum RightPaneView
{
	Hidden = 0,
	ActionView = 1,
	LogView = 2,
}

var editor_scale : float = 1
var right_pane_view : RightPaneView = RightPaneView.Hidden

var current_file_path : String = ""

var current_test_series : AutoPlaySuiteTestSeriesResource
var current_test : AutoPlaySuiteTestResource

var test_series_view : AutoPlaySuiteUiTestSeriesView
var action_list : AutoPlaySuiteActionList
var action_view : AutoPlaySuiteUiActionView
var logs_view : AutoPlaySuiteUiLogViewer

var logs : AutoPlaySuiteLogStore

var file_dialog : FileDialog

var test_name_field : LineEdit

var save_test_button : Button
var save_test_as_button : Button
var load_test_button : Button
var new_test_button : Button
var show_logs_button : Button

var item_affected_by_popup : TreeItem

var tests_to_run : Array[AutoPlaySuiteTestResource]
var currently_running_test : AutoPlaySuiteTestResource = null

var currently_setting_new_test : bool = false

var current_context : CurrentContext = CurrentContext.Running
var is_in_editor : bool:
	get:
		return current_context == CurrentContext.InEditor

var should_handle_input : bool:
	get:
		return current_context == CurrentContext.Running || current_context == CurrentContext.InPlugin_HasScreen

enum CurrentContext
{
	InEditor,
	InPlugin_HasScreen,
	InPlugin_DontHaveScreen,
	Running,
}

signal signal_on_current_test_saved

func _enter_tree() -> void:
	pass

func _register_plugin_singleton():
	var root := EditorInterface.get_base_control()
	root.set_meta("APS_EDITOR", self)

static func _get_plugin_singleton() -> AutoPlaySuite:
	var root := EditorInterface.get_base_control()
	return root.get_meta("APS_EDITOR")

func _ready() -> void:
	if Engine.is_editor_hint():
		current_context = CurrentContext.InEditor
	setup_ui.call_deferred()
	if Engine.is_editor_hint():
		editor_scale = EditorInterface.get_editor_scale()


func _on_editor_main_screen_changed(screen_name):
	if screen_name == "AutoTest":
		current_context = CurrentContext.InPlugin_HasScreen
	else:
		current_context = CurrentContext.InPlugin_DontHaveScreen

func _input(event: InputEvent) -> void:
	if !should_handle_input:
		return
	
	if action_list == null:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if test_series_view.current_selected_index == -1:
			print("No tests in series")
		else:
			print(test_series_view.current_test_series.paths_to_tests[test_series_view.current_selected_index])
	
	action_list.handle_input(event)

func setup_ui() -> void:
	if current_context == CurrentContext.Running:
		_setup_in_single_scene()
	
	var ed_scale : float = 1
	if Engine.is_editor_hint():
		ed_scale = EditorInterface.get_editor_scale()
	
	test_series_view = AutoPlaySuiteUiTestSeriesView.new()
	test_series_view.custom_minimum_size.x = 700 * ed_scale
	test_series_view.custom_minimum_size.y = 80 * ed_scale
	test_series_view.signal_on_test_changed.connect(_changed_active_test_of_series)
	test_series_view.signal_on_new_series.connect(_on_new_test_series)
	add_child(test_series_view)
	
	test_series_view.position = Vector2(100,10) * ed_scale
	
	test_series_view.signal_on_run_current_test_pressed.connect(_run_current_test)
	test_series_view.signal_on_run_all_tests_pressed.connect(_run_all_tests)
	
	action_list = AutoPlaySuiteActionList.new()
	add_child(action_list)
	action_list.signal_on_list_changed.connect(_sync_current_test_to_list)
	
	action_list.position = Vector2(100,100) * ed_scale
	action_list.custom_minimum_size.x = 250 * ed_scale
	action_list.custom_minimum_size.y = 300 * ed_scale
	
	action_list.signal_on_cell_selected.connect(_on_action_list_item_selected)
	
	var right_side_view_position := Vector2(400, 100) * ed_scale
	
	action_view = AutoPlaySuiteUiActionView.new()
	action_view.signal_on_action_changed.connect(_sync_current_test_to_list)
	add_child(action_view)
	action_view.position = right_side_view_position
	action_view._add_drop_down_item(&"[UNSET]")
	if current_context != CurrentContext.InEditor:
		action_view._fill_drop_down(AutoPlaySuiteActionLibrary.possible_actions.keys())
	action_view.run_action_button.pressed.connect(_run_selected_action)
	action_view.signal_on_action_id_changed.connect(_on_selected_action_id_changed)
	
	test_name_field = LineEdit.new()
	test_name_field.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(100, 10)  * ed_scale
	test_name_field.custom_minimum_size.x = 200 * ed_scale
	test_name_field.text_changed.connect(_test_name_field_changed)
	add_child(test_name_field)
	
	var test_name_label = Label.new()
	test_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	test_name_label.text = "Test Name:"
	test_name_label.position = test_name_field.position + Vector2(-210, 5)  * ed_scale
	test_name_label.custom_minimum_size.x = 200 * ed_scale
	add_child(test_name_label)
	
	#run_test_button.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(100, 50)  * ed_scale
	
	#run_all_button.position = run_test_button.position + Vector2(100, 0) * ed_scale

	save_test_button = Button.new()
	save_test_button.position = test_name_field.position + Vector2(0, 50)  * ed_scale
	save_test_button.text = "Save Test"
	add_child(save_test_button)
	save_test_button.pressed.connect(_save_test)
	
	save_test_as_button = Button.new()
	save_test_as_button.position = save_test_button.position + Vector2(100, 0) * ed_scale
	save_test_as_button.text = "Save Test As"
	add_child(save_test_as_button)
	save_test_as_button.pressed.connect(_save_test_as)
	
	load_test_button = Button.new()
	load_test_button.position = save_test_button.position + Vector2(0, 50) * ed_scale
	load_test_button.text = "Load Test"
	add_child(load_test_button)
	load_test_button.pressed.connect(_load_button_pressed)

	new_test_button = Button.new()
	new_test_button.position = load_test_button.position + Vector2(0, 50) * ed_scale
	new_test_button.text = "New Test"
	add_child(new_test_button)
	new_test_button.pressed.connect(_new_test)
	
	show_logs_button = Button.new()
	show_logs_button.position = load_test_button.position + Vector2(100, 50) * ed_scale
	show_logs_button.text = "Show Logs"
	add_child(show_logs_button)
	show_logs_button.pressed.connect(_show_logger)
	
	var debug_fill_button = Button.new()
	debug_fill_button.position = new_test_button.position + Vector2(-100, 0) * ed_scale
	debug_fill_button.text = "Debug Fill"
	add_child(debug_fill_button)
	debug_fill_button.pressed.connect(_debug_fill)
	
	logs_view = AutoPlaySuiteUiLogViewer.new()
	add_child(logs_view)
	logs_view.position = right_side_view_position
	logs_view.custom_minimum_size = Vector2(600, 300) * ed_scale
	logs_view.dict_view.custom_minimum_size = Vector2(600, 300) * ed_scale
	logs_view.dict_view.create_tree()
	
	logs = AutoPlaySuiteLogStore.get_shared()
	#add_child(logs)
	
	_hide_all_right_side_elements()
	
	if is_in_editor:
		_setup_in_editor()
	
	new_test_button.pressed.emit()

func _setup_in_single_scene():
	init_plugin()

func _setup_in_editor():
	pass

func _logger_message_received(data: Array):
	logs.handle_debugger_message(data)

func _show_action_view():
	_hide_all_right_side_elements()
	action_view.visible = true
	right_pane_view = RightPaneView.ActionView

func _show_logger():
	_hide_all_right_side_elements()
	logs_view.visible = true
	right_pane_view = RightPaneView.LogView

func _hide_all_right_side_elements():
	action_view.visible = false
	logs_view.visible = false
	right_pane_view = RightPaneView.Hidden

func _on_action_list_item_selected():
	var selected = action_list.last_selected
	var action_resource : AutoPlaySuiteActionResource = action_list.backing_dictionary[selected]
	action_view._set_action(action_resource)
	_show_action_view()

func _on_selected_action_id_changed(new_id : String):
	action_list.update_display_text_of_selected_index()

func _save_test(path : String = ""):
	if file_dialog != null:
		return
	if action_list.get_item_count() == 0:
		return
	
	if path == "":
		if current_file_path == "":
			_save_test_as()
			return
		path = current_file_path
	
	if path.begins_with("u"):
		path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
	
	current_file_path = path
	
	_sync_current_test_to_list()
	
	current_test.take_over_path(path)
	ResourceSaver.save(current_test, path)
	
	var uid : int = ResourceSaver.get_resource_id_for_path(path)
	var uid_string : String = ResourceUID.id_to_text(uid)
	current_test.test_uid = uid_string
	test_series_view._update_path_to_current_test(uid_string)
	signal_on_current_test_saved.emit()

func _save_test_as():
	if action_list.get_item_count() == 0:
		return

	if file_dialog != null:
		return
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	_set_file_dialog_size_and_position()
	file_dialog.show()
	file_dialog.add_filter("*.test.tres")
	file_dialog.canceled.connect(_file_dialog_canceled)
	file_dialog.file_selected.connect(_save_file_chosen)

func _save_file_chosen(path : String):
	file_dialog = null
	_save_test(path)

func _load_button_pressed():
	if file_dialog != null:
		return
	
	file_dialog = FileDialog.new()
	add_child(file_dialog)
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE 
	file_dialog.add_filter("*.test.tres")
	file_dialog.file_selected.connect(_load_test)
	_set_file_dialog_size_and_position()
	file_dialog.canceled.connect(_file_dialog_canceled)
	file_dialog.show()

func _set_file_dialog_size_and_position():
	file_dialog.min_size = Vector2(600, 400) * editor_scale
	file_dialog.position = global_position

func _load_test(path : String):
	file_dialog = null
	current_file_path = path
	var test : AutoPlaySuiteTestResource = load(path)
	
	if test == null:
		printerr("Selected file was not a Test Resource!")
		return
	
	var new_test : AutoPlaySuiteTestResource = test.duplicate(true)
	var uid_string : String = ResourceUID.id_to_text(ResourceSaver.get_resource_id_for_path(path))
	new_test.test_uid = uid_string
	test_series_view.add_test(new_test)
	test_series_view._update_path_to_current_test(uid_string)
	
	#var uid_string : String = ResourceUID.id_to_text(ResourceSaver.get_resource_id_for_path(path))
	#test_series_view._update_path_to_current_test(uid_string)
	#_set_current_test(test.duplicate(true))

func _file_dialog_canceled():
	file_dialog = null

func _new_test():
	current_file_path = ""
	current_test = AutoPlaySuiteTestResource.new()
	var test_name : String = "test #"
	for n in 4:
		test_name += str(randi_range(0,9)) 
	test_name_field.text = test_name
	current_test.test_name = test_name
	action_list.empty_list()
	test_series_view.add_test(current_test)

func _on_new_test_series():
	_new_test()

func _sync_current_test_to_list():
	if currently_setting_new_test:
		return
	
	current_test.actions.clear()
	var all_actions : Array = action_list.get_all_items()
	current_test.actions.append_array(all_actions)

func _changed_active_test_of_series(new_test : AutoPlaySuiteTestResource):
	current_file_path = test_series_view._get_test_uid_path(new_test)
	_set_current_test(new_test)

func _set_current_test(new_test : AutoPlaySuiteTestResource):
	currently_setting_new_test = true
	current_test = new_test
	test_name_field.text = current_test.test_name
	action_list.empty_list()
	for action in current_test.actions:
		action_list.add_and_bind_item(action.action_id, action)	
	currently_setting_new_test = false
	_load_log_of_current_test()

func _test_name_field_changed(new_name : String):
	current_test.test_name = new_name
	test_series_view.current_test_name_changed(new_name)

func _debug_fill():
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "jamen de string"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print Float", 1, "den här texten syns inte!"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "en till string!"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print Hi X Seconds", 0.5, "jupp"))
	current_test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Quit", 0, "en till string!"))
	
	for action in current_test.actions:
		action_list.add_and_bind_item(action.action_id, action)	

func _run_selected_action():
	if action_view.underlying_action != null:
		AutoPlaySuiteActionLibrary.possible_actions[action_view.underlying_action.action_id].on_enter.call(action_view.underlying_action)

func _run_current_test():
	if current_file_path == "":
		printerr("Test must be saved to file before running it!")
		return
	
	_save_test()
	
	_prepare_for_testing()
	
	_run_single_test(current_test, _end_testing)
	

func _prepare_for_testing():
	logs.clear_logs()
	_setup_environment_for_testing()

func _end_testing():
	_load_log_of_current_test()
	_show_logger()
	_restore_environment_after_testing()
	currently_running_test = null

func _load_log_of_current_test():
	if !logs.log_dictionary.has(current_test.test_name):
		logs_view.set_data({"No Data":"Please run test to generate log data"})
		return
	
	logs_view.set_data(logs.log_dictionary[current_test.test_name])

func _setup_environment_for_testing():
	OS.set_environment("DoAutoTesting", "true")

func _run_single_test(test_resource : AutoPlaySuiteTestResource, call_on_finished : Callable):
	currently_running_test = test_resource
	var path := test_series_view._get_test_uid_path(test_resource)
	_set_current_test_file_path_environment(path)
	
	EditorInterface.play_main_scene()
	await _wait_until_game_exits()
	
	call_on_finished.call()

func _set_current_test_file_path_environment(path : String):
	OS.set_environment("AutoTestPath", path)

func _restore_environment_after_testing():
	OS.set_environment("DoAutoTesting", "")
	OS.set_environment("AutoTestPath", "")

func _run_all_tests():
	tests_to_run.clear()
	tests_to_run.append_array(test_series_view._get_all_tests_in_order())
	
	_prepare_for_testing()
	_run_next_test()
	

func _run_next_test():
	if tests_to_run.size() == 0:
		_end_testing()
		return
	
	var next_test = tests_to_run[0]
	tests_to_run.remove_at(0)
	_run_single_test(next_test, _run_next_test)

func _wait_until_game_exits() -> void:
	# Give the editor one frame to flip into "playing" state.
	await get_tree().process_frame
	while EditorInterface.is_playing_scene():
		await get_tree().process_frame

func init_plugin():
	var custom_instructions = load("res://addons/auto_play_suite_editor/custom_instructions/custom_auto_play_instructions.gd").new()
	custom_instructions.hook_into_suite()
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	current_test = AutoPlaySuiteTestResource.new()
