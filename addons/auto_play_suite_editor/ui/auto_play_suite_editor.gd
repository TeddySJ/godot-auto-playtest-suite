@tool
extends Control
class_name AutoPlaySuite

const DEBUGGER_MESSAGE_GRACE_MSEC : int = 500
const RUN_START_TIMEOUT_MSEC : int = 15000

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

enum CurrentContext
{
	InEditor,
	InPlugin_HasScreen,
	InPlugin_DontHaveScreen,
	Running,
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

var test_has_exited_properly : bool = false
var received_exit_message : bool = false
var current_test_exit_code : int = 0

var tests_to_run : Array[AutoPlaySuiteTestResource]
var currently_running_test : AutoPlaySuiteTestResource = null
var testing_in_progress : bool = false
var running_test_series : bool = false
var series_cancelled : bool = false
var accumulated_test_results : Dictionary[String, bool] = {}
var debugger_session_test_keys : Dictionary[int, String] = {}
var debugger_session_run_ids : Dictionary[int, String] = {}
var debugger_sessions : Dictionary[int, EditorDebuggerSession] = {}
var current_debugger_session_id : int = -1
var current_test_run_id : int = 0
var current_test_run_token : String = ""
var run_started : bool = false
var current_run_will_quit : bool = false
var current_run_failure_message : String = ""

var current_context : CurrentContext = CurrentContext.Running
var is_in_editor : bool:
	get:
		return current_context == CurrentContext.InEditor

var should_handle_input : bool:
	get:
		return current_context == CurrentContext.Running || current_context == CurrentContext.InPlugin_HasScreen


signal signal_on_test_passed_or_failed_evaluation(test, success)

static func set_and_show_popup(new_popup : Popup):
	if is_instance_valid(shared_popup):
		shared_popup.queue_free()
	shared_popup = null
	if !is_instance_valid(new_popup):
		return
	shared_popup = new_popup
	shared_popup.popup_hide.connect(_on_shared_popup_hidden.bind(shared_popup), CONNECT_ONE_SHOT)
	shared_popup.show()

static func _on_shared_popup_hidden(popup : Popup) -> void:
	if shared_popup == popup:
		shared_popup = null
	if is_instance_valid(popup):
		popup.queue_free()
	
static func _get_plugin_singleton() -> AutoPlaySuite:
	var root := EditorInterface.get_base_control()
	var instance : AutoPlaySuite = root.get_meta("APS_EDITOR", null)
	return instance if is_instance_valid(instance) else null

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	if !is_instance_valid(shared_popup) || is_ancestor_of(shared_popup):
		shared_popup = null

func _register_plugin_singleton():
	var root := EditorInterface.get_base_control()
	root.set_meta("APS_EDITOR", self)

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
	if testing_in_progress:
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
	action_view.signal_on_action_changed.connect(_on_action_changed)
	add_child(action_view)
	action_view.position = right_side_view_position
	action_view._add_drop_down_item(&"[UNSET]")
	if current_context != CurrentContext.InEditor:
		action_view._fill_drop_down(AutoPlaySuiteActionLibrary.possible_actions.keys())
	#action_view.run_action_button.pressed.connect(_run_selected_action)
	action_view.signal_on_action_id_changed.connect(current_test_view._on_selected_action_id_changed)
	
	#run_test_button.position = Vector2(0, action_list.position.y + action_list.custom_minimum_size.y) + Vector2(100, 50)  * ed_scale
	
	#run_all_button.position = run_test_button.position + Vector2(100, 0) * ed_scale

	show_logs_button = Button.new()
	show_logs_button.position = action_view.position + Vector2(0, action_view.main_panel.custom_minimum_size.y + 30 * ed_scale)
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
	current_test_view.signal_on_current_test_modified.connect(test_series_view.mark_test_dirty)
	current_test_view.signal_on_action_list_changed.connect(_current_action_list_changed)
	current_test_view.signal_on_before_test_change.connect(action_view.commit_pending_edits)
	current_test_view.signal_on_before_test_save.connect(action_view.commit_pending_edits)
	current_test_view.signal_on_before_action_context_change.connect(action_view.commit_pending_edits)
	test_series_view.signal_on_before_series_operation.connect(action_view.commit_pending_edits)
	
	signal_on_test_passed_or_failed_evaluation.connect(test_series_view._on_test_failed_or_passed_test)

func _setup_in_single_scene():
	init_plugin()

func _setup_in_editor():
	pass

func _debugger_session_started(session_id : int) -> void:
	if currently_running_test == null:
		return
	current_debugger_session_id = session_id

func _debugger_session_setup(session_id : int, session : EditorDebuggerSession) -> void:
	debugger_sessions[session_id] = session

func _debugger_session_stopped(session_id : int) -> void:
	if current_debugger_session_id == session_id:
		current_debugger_session_id = -1

func _logger_message_received(data: Array, session_id : int):
	if data.size() < 3:
		return
	var message_run_token := str(data[0])
	if message_run_token != current_test_run_token:
		return
	if debugger_session_run_ids.get(session_id, "") != message_run_token:
		return
	var test_key : String = debugger_session_test_keys.get(session_id, "")
	if test_key.is_empty():
		return
	logs.handle_debugger_message(data.slice(1), test_key)

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
	var loaded_resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)
	
	if !(loaded_resource is AutoPlaySuiteTestResource):
		printerr("Selected file was not a Test Resource!")
		return
	
	var test : AutoPlaySuiteTestResource = loaded_resource
	var new_test : AutoPlaySuiteTestResource = test.duplicate(true)
	var uid_string : String = ResourceUID.id_to_text(ResourceSaver.get_resource_id_for_path(path))
	new_test.test_uid = uid_string
	if !test_series_view.add_test(new_test):
		return
	test_series_view._update_path_to_current_test(uid_string)
	current_test_view.current_file_path = uid_string
	
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
	action_view.visible = false

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
	if testing_in_progress:
		printerr("A test run is already in progress.")
		return
	if current_test_view.current_file_path == "":
		printerr("Test must be saved to file before running it!")
		return
	
	if !current_test_view._save_test():
		return
	
	_prepare_for_testing(false)
	
	_run_single_test(current_test_view.current_test, _end_testing)
	

func _prepare_for_testing(is_series : bool):
	testing_in_progress = true
	running_test_series = is_series
	series_cancelled = false
	accumulated_test_results.clear()
	if !_is_game_running():
		debugger_session_test_keys.clear()
		debugger_session_run_ids.clear()
		current_debugger_session_id = -1
	current_test_run_id = 0
	current_test_run_token = ""
	run_started = false
	test_series_view.set_testing_in_progress(true)
	current_test_view.set_testing_in_progress(true)
	action_view.set_testing_in_progress(true)
	logs.clear_logs()
	_setup_environment_for_testing()

func _end_testing():
	_load_log_of_current_test()
	_show_logger()
	_restore_environment_after_testing()
	tests_to_run.clear()
	currently_running_test = null
	testing_in_progress = false
	running_test_series = false
	test_series_view.set_testing_in_progress(false)
	current_test_view.set_testing_in_progress(false)
	action_view.set_testing_in_progress(false)

func _on_test_ended(test : AutoPlaySuiteTestResource):
	var test_key := test.get_identity_key()
	var success := _test_passed(test)
	if accumulated_test_results.has(test_key):
		success = accumulated_test_results[test_key] && success
	accumulated_test_results[test_key] = success
	signal_on_test_passed_or_failed_evaluation.emit(test, success)

func _test_passed(test : AutoPlaySuiteTestResource) -> bool:
	if !current_run_failure_message.is_empty():
		return false

	if received_exit_message && current_test_exit_code != 0:
		return false

	if !test_has_exited_properly && test.premature_end_is_error:
		return false
	
	var test_key := test.get_identity_key()
	if logs.has_failed_evaluations(test_key):
		return false

	return true

func _load_log_of_current_test():
	var test_key := current_test_view.current_test.get_identity_key()
	if !logs.has_log_data(test_key):
		logs_view.set_data({"No Data":"Please run test to generate log data"})
		return
	
	logs_view.set_data(logs.get_log_data(test_key))

func _setup_environment_for_testing():
	OS.set_environment("DoAutoTesting", "true")

func _run_single_test(test_resource : AutoPlaySuiteTestResource, call_on_finished : Callable):
	currently_running_test = test_resource
	current_test_run_id += 1
	current_test_run_token = "%d-%d" % [Time.get_ticks_usec(), current_test_run_id]
	run_started = false
	current_run_will_quit = false
	current_run_failure_message = ""
	var path := test_series_view._get_test_uid_path(test_resource)
	_set_current_test_file_path_environment(path)
	OS.set_environment("AutoTestRunToken", current_test_run_token)
	test_has_exited_properly = false
	received_exit_message = false
	current_test_exit_code = 0
	
	var start_requested := true
	if _is_game_running():
		start_requested = _send_test_to_running_game(path, current_test_run_token)
		if !start_requested:
			_record_current_run_failure("The running game does not have an active Auto Play Suite debugger session.")
			_stop_game()
	else:
		current_debugger_session_id = -1
		EditorInterface.play_main_scene()
	var started_successfully := false
	if start_requested:
		started_successfully = await _wait_until_run_starts()
	if start_requested && !started_successfully:
		if _is_game_running():
			_record_current_run_failure("The game started, but the Auto Play Suite runner did not report in within %.1f seconds." % [float(RUN_START_TIMEOUT_MSEC) / 1000.0])
			_stop_game()
		else:
			_record_current_run_failure("The game exited before the Auto Play Suite runner reported that it had started.")
	await _wait_until_run_finishes_or_game_exits()
	if current_run_will_quit:
		await _wait_until_game_exits()
	if !received_exit_message:
		await _wait_for_exit_message()
	
	_on_test_ended(test_resource)
	if _should_cancel_series_after_test(test_resource):
		series_cancelled = true
	call_on_finished.call()

func _should_cancel_series_after_test(test_resource : AutoPlaySuiteTestResource) -> bool:
	return (
		running_test_series
		&& test_resource.stop_series_on_error
		&& logs.has_failed_evaluations(test_resource.get_identity_key())
	)

func _set_current_test_file_path_environment(path : String):
	OS.set_environment("AutoTestPath", path)

func _restore_environment_after_testing():
	OS.set_environment("DoAutoTesting", "")
	OS.set_environment("AutoTestPath", "")
	OS.set_environment("AutoTestRunToken", "")

func _run_all_tests():
	if testing_in_progress:
		printerr("A test run is already in progress.")
		return
	tests_to_run.clear()
	tests_to_run.append_array(test_series_view._get_all_tests_in_order())
	for test in tests_to_run:
		var validation_errors := test.get_validation_errors()
		if !validation_errors.is_empty():
			for error in validation_errors:
				printerr("Cannot run test '%s': %s" % [test.test_name, error])
			return
	
	_prepare_for_testing(true)
	_run_next_test()

func _run_next_test():
	if series_cancelled || tests_to_run.size() == 0:
		_end_testing()
		return
	
	var next_test = tests_to_run[0]
	tests_to_run.remove_at(0)
	_run_single_test(next_test, _run_next_test)

func _wait_until_game_exits() -> void:
	# Give the editor one frame to flip into "playing" state.
	await get_tree().process_frame
	while _is_game_running():
		await get_tree().process_frame

func _wait_until_run_finishes_or_game_exits() -> void:
	await get_tree().process_frame
	while _is_game_running() && !received_exit_message:
		await get_tree().process_frame

func _send_test_to_running_game(path : String, run_token : String) -> bool:
	var session : EditorDebuggerSession = debugger_sessions.get(current_debugger_session_id)
	if session == null || !session.is_active():
		return false
	session.send_message("aps:start_test", [path, run_token])
	return true

func _wait_until_run_starts(timeout_msec : int = RUN_START_TIMEOUT_MSEC) -> bool:
	var deadline := Time.get_ticks_msec() + timeout_msec
	var observed_running_game := false
	while Time.get_ticks_msec() < deadline:
		if run_started:
			return true
		if _is_game_running():
			observed_running_game = true
		elif observed_running_game:
			return false
		await get_tree().process_frame
	return run_started

func _is_game_running() -> bool:
	return EditorInterface.is_playing_scene()

func _stop_game() -> void:
	EditorInterface.stop_playing_scene()

func _record_current_run_failure(message : String) -> void:
	current_run_failure_message = message
	printerr(message)
	if currently_running_test == null:
		return
	logs.handle_debugger_message(
		["Default Logger", "Failed Evaluation", "Editor-%d" % current_test_run_id, message],
		currently_running_test.get_identity_key()
	)

func _wait_for_exit_message() -> void:
	var deadline := Time.get_ticks_msec() + DEBUGGER_MESSAGE_GRACE_MSEC
	while !received_exit_message && Time.get_ticks_msec() < deadline:
		await get_tree().process_frame

func _current_action_list_changed():
	current_test_view.deselect_all()
	action_view.visible = false

func init_plugin():
	AutoPlaySuiteInstructionLoader.LoadAllInstructions()
	
	current_test_series = AutoPlaySuiteTestSeriesResource.new()
	#current_test_view.current_test = AutoPlaySuiteTestResource.new()

func _on_action_list_item_selected(action_resource):
	action_view._set_action(action_resource)
	_show_action_view()

func _on_action_changed(action_resource : AutoPlaySuiteActionResource) -> void:
	var action_is_in_current_view := (
		current_test_view.action_list.get_all_items().has(action_resource)
		|| current_test_view.post_action_list.get_all_items().has(action_resource)
	)
	if action_is_in_current_view:
		current_test_view._sync_current_test_to_list(true)
	else:
		test_series_view.mark_action_dirty(action_resource)

func _on_current_test_saved(uid_string : String):
	test_series_view._update_path_to_current_test(uid_string)
	test_series_view.mark_test_saved(current_test_view.current_test)

func _system_message_received(data : Array, session_id : int):
	if data.size() < 2 || currently_running_test == null:
		return
	var message_type := StringName(data[0])
	var message_run_token := str(data[1])
	if message_run_token != current_test_run_token:
		return

	if message_type == &"RunStarted":
		debugger_session_test_keys[session_id] = currently_running_test.get_identity_key()
		debugger_session_run_ids[session_id] = message_run_token
		current_debugger_session_id = session_id
		run_started = true
		return
	
	if message_type == &"RunFinished" && debugger_session_run_ids.get(session_id, "") == message_run_token:
		test_has_exited_properly = true
		received_exit_message = true
		if data.size() > 2:
			current_test_exit_code = int(data[2])
		if data.size() > 3:
			current_run_will_quit = bool(data[3])
