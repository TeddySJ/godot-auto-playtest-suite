extends SceneTree

const FIRST_PATH := "res://tests/regression/_handoff_first.test.tres"
const SECOND_PATH := "res://tests/regression/_handoff_second.test.tres"

func _initialize() -> void:
	_run_regression.call_deferred()

func _run_regression() -> void:
	var editor : AutoPlaySuite = null
	for _frame in 300:
		var editor_root := EditorInterface.get_base_control()
		if editor_root.has_meta("APS_EDITOR"):
			editor = editor_root.get_meta("APS_EDITOR") as AutoPlaySuite
		if editor != null && editor.test_series_view != null:
			break
		await process_frame
	if editor == null || editor.test_series_view == null:
		_finish(false, "The editor plugin did not initialize.")
		return

	var first := _make_test("Handoff First", "first")
	var second := _make_test("Handoff Second", "second")
	if ResourceSaver.save(first, FIRST_PATH) != OK || ResourceSaver.save(second, SECOND_PATH) != OK:
		_finish(false, "The temporary tests could not be saved.")
		return

	var series := AutoPlaySuiteTestSeriesResource.new()
	series.test_series_name = "Persistent handoff regression"
	series.paths_to_tests = [FIRST_PATH, SECOND_PATH]
	series.number_of_runs_per_test = [1, 1]
	if !editor.test_series_view._set_current_series(series):
		_finish(false, "The temporary test series could not be loaded.")
		return

	editor._run_all_tests()
	var deadline := Time.get_ticks_msec() + 20000
	while editor.testing_in_progress && Time.get_ticks_msec() < deadline:
		await process_frame

	var all_tests_passed := editor.accumulated_test_results.size() == 2
	for result : bool in editor.accumulated_test_results.values():
		all_tests_passed = all_tests_passed && result
	var success := (
		!editor.testing_in_progress
		&& editor.current_run_failure_message.is_empty()
		&& editor.run_started
		&& editor.received_exit_message
		&& EditorInterface.is_playing_scene()
		&& editor.current_debugger_session_id >= 0
		&& editor.debugger_sessions.has(editor.current_debugger_session_id)
		&& all_tests_passed
	)
	_finish(success, "The second test did not complete through the existing debugger session.")

func _make_test(test_name : String, text : String) -> AutoPlaySuiteTestResource:
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = test_name
	test.actions.append(AutoPlaySuiteActionResource.Create(&"[Debug] Print String", 0.0, text))
	return test

func _finish(success : bool, failure_message : String) -> void:
	if EditorInterface.is_playing_scene():
		EditorInterface.stop_playing_scene()
	for _frame in 30:
		await process_frame
	_remove_temporary_resource(FIRST_PATH)
	_remove_temporary_resource(SECOND_PATH)
	if success:
		print("PERSISTENT_HANDOFF_EDITOR_REGRESSION_SUCCESS")
		quit(0)
		return
	push_error(failure_message)
	quit(1)

func _remove_temporary_resource(path : String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
