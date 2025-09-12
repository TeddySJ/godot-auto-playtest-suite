@tool
extends Control
class_name AutoPlaySuite

static var Singleton : AutoPlaySuite:
	get:
		return _get_plugin_singleton()

static var shared_popup : Popup

enum RightPaneView
{
	Hidden = 0,
	ActionView = 1,
	LogView = 2,
}

enum EditorPanes
{
	ActionListView,
	ActionSeriesView,
	ActionView,
	LogView,
}



var editor_scale : float = 1
var right_pane_view : RightPaneView = RightPaneView.Hidden

var current_test_series : AutoPlaySuiteTestSeriesResource

var test_series_view : AutoPlaySuiteUiTestSeriesView
var current_test_view : AutoPlaySuiteUiCurrentTestView
var action_view : AutoPlaySuiteUiActionView
var logs_view : AutoPlaySuiteUiLogViewer

var logs : AutoPlaySuiteLogStore

var file_dialog : FileDialog

var show_logs_button : Button

var item_affected_by_popup : TreeItem

var tests_to_run : Array[AutoPlaySuiteTestResource]
var currently_running_test : AutoPlaySuiteTestResource = null

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

signal signal_on_test_passed_or_failed_evaluation(test, success)

static func set_and_show_popup(new_popup : Popup):
	if shared_popup != null:
		shared_popup.hide()
		shared_popup = null
	shared_popup = new_popup
	shared_popup.show()
	

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
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	

func _on_editor_main_screen_changed(screen_name):
	if screen_name == "AutoTest":
		current_context = CurrentContext.InPlugin_HasScreen
	else:
		current_context = CurrentContext.InPlugin_DontHaveScreen

func _input(event: InputEvent) -> void:
	if !should_handle_input:
		return
		
	if current_test_view == null:
		return
		
	if Input.is_action_pressed("ui_focus_next") && event.is_action_pressed("ui_cancel"):
		_debug_fill.call_deferred()
	
	if event.is_action_pressed("ui_cancel"):
		if test_series_view.current_selected_index == -1:
			print("No tests in series")
		else:
			print(test_series_view.current_test_series.paths_to_tests[test_series_view.current_selected_index])
	
	current_test_view.handle_input(event)

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
	test_series_view.signal_on_new_test_button_pressed.connect(_new_test)
	test_series_view.signal_on_load_test_button_pressed.connect(_load_button_pressed)
	
	current_test_view = AutoPlaySuiteUiCurrentTestView.new()
	add_child(current_test_view)
	current_test_view.position = Vector2(100,100) * ed_scale
	
	var right_side_view_position := Vector2(430, 100) * ed_scale
	
	action_view = AutoPlaySuiteUiActionView.new()
	action_view.signal_on_action_changed.connect(current_test_view._sync_current_test_to_list)
	add_child(action_view)
	action_view.position = right_side_view_position
	action_view._add_drop_down_item(&"[UNSET]")
	if current_context != CurrentContext.InEditor:
		action_view._fill_drop_down(AutoPlaySuiteActionLibrary.possible_actions.keys())
	action_view.run_action_button.pressed.connect(_run_selected_action)
	action_view.signal_on_action_id_changed.connect(current_test_view._on_selected_action_id_changed)
	
	#run_test_button.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(100, 50)  * ed_scale
	
	#run_all_button.position = run_test_button.position + Vector2(100, 0) * ed_scale

	show_logs_button = Button.new()
	show_logs_button.position = action_view.position + Vector2(0, 430) * ed_scale
	show_logs_button.text = "Show Logs"
	add_child(show_logs_button)
	show_logs_button.pressed.connect(_show_logger)
	
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
	
	_new_test()
	
	# Cross signals
	current_test_view.signal_on_test_name_changed.connect(test_series_view.current_test_name_changed)
	current_test_view.signal_on_action_list_item_selected.connect(_on_action_list_item_selected)
	current_test_view.signal_on_current_test_saved.connect(_on_current_test_saved)
	
	signal_on_test_passed_or_failed_evaluation.connect(test_series_view._on_test_failed_or_passed_test)

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
	current_test_view.current_file_path = path
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
	current_test_view.new_test()
	test_series_view.add_test(current_test_view.current_test)

func _on_new_test_series():
	_new_test()

func _changed_active_test_of_series(new_test : AutoPlaySuiteTestResource):
	current_test_view.current_file_path = test_series_view._get_test_uid_path(new_test)
	_set_current_test(new_test)

func _set_current_test(new_test : AutoPlaySuiteTestResource):
	current_test_view.set_current_test(new_test)
	_load_log_of_current_test()

func _debug_fill():
	
	#action_list.empty_list()
	
	var actions : Array[AutoPlaySuiteActionResource] = []
	actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0, "jamen de string"))
	actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print Float", 1, "den här texten syns inte!"))
	actions.append(AutoPlaySuiteActionResource.Create(&"[Wait] Wait X Seconds", 0, "en till string!"))
	actions.append(AutoPlaySuiteActionResource.Create(&"[Logging] Start Logger", 0.5, "jupp"))
	actions.append(AutoPlaySuiteActionResource.Create(&"[Engine] Quit", 0, "en till string!"))
	
	for action in actions:
		current_test_view.action_list.add_and_bind_item(action.action_id, action)

func _run_selected_action():
	if action_view.underlying_action != null:
		AutoPlaySuiteActionLibrary.possible_actions[action_view.underlying_action.action_id].on_enter.call(action_view.underlying_action)

func _run_current_test():
	if current_test_view.current_file_path == "":
		printerr("Test must be saved to file before running it!")
		return
	
	current_test_view._save_test()
	
	_prepare_for_testing()
	
	_run_single_test(current_test_view.current_test, _end_testing)
	

func _prepare_for_testing():
	logs.clear_logs()
	_setup_environment_for_testing()

func _end_testing():
	_load_log_of_current_test()
	_show_logger()
	_restore_environment_after_testing()
	currently_running_test = null

func _on_test_ended(test : AutoPlaySuiteTestResource):
	signal_on_test_passed_or_failed_evaluation.emit(test, _test_passed(test))

func _test_passed(test : AutoPlaySuiteTestResource) -> bool:
	var log_dict : Dictionary = logs.log_dictionary[test.test_name]
	
	if log_dict.has(&"Default Logger"):
		var def_log : Dictionary = log_dict[&"Default Logger"]
		if def_log.has(&"Failed Evals"):
			return false
	return true

func _load_log_of_current_test():
	if !logs.log_dictionary.has(current_test_view.current_test.test_name):
		logs_view.set_data({"No Data":"Please run test to generate log data"})
		return
	
	logs_view.set_data(logs.log_dictionary[current_test_view.current_test.test_name])

func _setup_environment_for_testing():
	OS.set_environment("DoAutoTesting", "true")

func _run_single_test(test_resource : AutoPlaySuiteTestResource, call_on_finished : Callable):
	currently_running_test = test_resource
	var path := test_series_view._get_test_uid_path(test_resource)
	_set_current_test_file_path_environment(path)
	
	EditorInterface.play_main_scene()
	await _wait_until_game_exits()
	
	_on_test_ended(test_resource)
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
	AutoPlaySuiteInstructionLoader.LoadAllInstructions()
	
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	#current_test_view.current_test = AutoPlaySuiteTestResource.new()

func _on_action_list_item_selected(action_resource):
	action_view._set_action(action_resource)
	_show_action_view()

func _on_current_test_saved(uid_string : String):
	test_series_view._update_path_to_current_test(uid_string)
