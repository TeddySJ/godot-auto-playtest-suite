extends SceneTree

var failures : PackedStringArray = []

class StartupProbe extends AutoPlaySuite:
	var simulated_game_running : bool = false

	func _ready() -> void:
		pass

	func _is_game_running() -> bool:
		return simulated_game_running

	func _stop_game() -> void:
		simulated_game_running = false

func _initialize() -> void:
	_run_validation.call_deferred()

func _assert_true(condition : bool, message : String) -> void:
	if !condition:
		failures.append(message)

func _make_test(test_name : String, test_uid : String) -> AutoPlaySuiteTestResource:
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = test_name
	test.test_uid = test_uid
	return test

func _run_validation() -> void:
	var view := AutoPlaySuiteUiTestSeriesView.new()
	root.add_child(view)
	await process_frame

	var first := _make_test("Duplicate Name", "uid://series-validation-first")
	var second := _make_test("Duplicate Name", "uid://series-validation-second")
	_assert_true(view.add_test(first), "The first test should be added.")
	view._update_path_to_current_test(first.test_uid)
	_assert_true(view.add_test(second), "A different test with the same display name should be added.")
	view._update_path_to_current_test(second.test_uid)
	_assert_true(view._get_index_of_test(first) == 0, "The first duplicate-name test should retain index 0.")
	_assert_true(view._get_index_of_test(second) == 1, "The second duplicate-name test should retain index 1.")

	view.current_test_series.number_of_runs_per_test = [2, 3]
	var expanded_runs := view._get_all_tests_in_order()
	_assert_true(expanded_runs.size() == 5, "Run counts should expand the series queue.")
	_assert_true(expanded_runs[0] == first && expanded_runs[1] == first, "The first test should run twice.")
	_assert_true(expanded_runs[2] == second && expanded_runs[4] == second, "The second test should run three times.")

	view._remove_test_button_pressed()
	_assert_true(!view.underlying_dictionary.values().has(second), "Removing a test should erase its dictionary entry.")
	_assert_true(view.add_test(second), "A removed test should be addable again.")
	view._update_path_to_current_test(second.test_uid)

	view.current_file_path = "res://tests/previous-series.testseries.tres"
	view._new_series_button_pressed()
	_assert_true(view.current_file_path.is_empty(), "A new series should not retain the previous save path.")
	_assert_true(!view.current_test_series.test_series_name.is_empty(), "A new series should store its generated name.")

	var loaded_series := AutoPlaySuiteTestSeriesResource.new()
	loaded_series.paths_to_tests = [
		"uid://2n2ewnuiafo4",
		"uid://gb1ho367v6mt",
		"uid://cvvelucg4n1h0",
	]
	_assert_true(view._set_current_series(loaded_series), "A valid legacy series should load.")
	_assert_true(view.test_button_list.size() == 3, "Loaded test buttons and paths should remain aligned.")
	_assert_true(view.current_test_series.number_of_runs_per_test == [1, 1, 1], "Legacy series should default to one run per test.")
	var accepted_series := view.current_test_series
	var duplicate_series := AutoPlaySuiteTestSeriesResource.new()
	duplicate_series.paths_to_tests = ["uid://2n2ewnuiafo4", "uid://2n2ewnuiafo4"]
	_assert_true(!view._set_current_series(duplicate_series), "A series containing the same test twice should be rejected.")
	_assert_true(view.current_test_series == accepted_series && view.test_button_list.size() == 3, "A rejected series should not disturb the active series.")

	view.set_testing_in_progress(true)
	_assert_true(view.testing_in_progress, "The series view should enter its testing state.")
	_assert_true(view.run_all_tests_button.disabled && view.remove_test_button.disabled, "Run and mutation controls should be disabled during testing.")
	view.set_testing_in_progress(false)
	_assert_true(!view.run_all_tests_button.disabled && !view.remove_test_button.disabled, "Series controls should be restored after testing.")

	var editor := AutoPlaySuite.new()
	editor.logs = AutoPlaySuiteLogStore.new()
	var repeated_test := _make_test("Repeated", "uid://series-validation-repeated")
	repeated_test.premature_end_is_error = true
	editor.test_has_exited_properly = false
	editor._on_test_ended(repeated_test)
	editor.test_has_exited_properly = true
	editor._on_test_ended(repeated_test)
	_assert_true(!editor.accumulated_test_results[repeated_test.get_identity_key()], "A later passing run should not erase an earlier failure.")

	var next_test := _make_test("Next", "uid://series-validation-next")
	editor.currently_running_test = repeated_test
	editor.current_test_run_id = 1
	editor.current_test_run_token = "run-one"
	editor._debugger_session_started(41)
	editor._system_message_received([&"RunStarted", "run-one"], 41)
	editor._debugger_session_stopped(41)
	editor.currently_running_test = next_test
	editor.current_test_run_id = 2
	editor.current_test_run_token = "run-two"
	editor.test_has_exited_properly = false
	editor._system_message_received([&"RunFinished", "run-one", 0], 41)
	_assert_true(editor.current_debugger_session_id == -1, "A known session from an earlier run should not become the current session.")
	_assert_true(!editor.test_has_exited_properly, "A delayed exit message should not mark the next run as properly exited.")
	editor._logger_message_received(["run-one", "Default Logger", "Set Data", "source", "first"], 41)
	_assert_true(!editor.logs.log_dictionary.has(repeated_test.get_identity_key()), "Messages arriving after their run has ended should be ignored.")
	_assert_true(!editor.logs.log_dictionary.has(next_test.get_identity_key()), "Late messages should not leak into the next test.")
	editor._debugger_session_started(41)
	_assert_true(editor.current_debugger_session_id == 41, "A reused debugger session should bind to the new run when it starts.")
	editor._system_message_received([&"RunStarted", "run-two"], 41)
	_assert_true(editor.debugger_session_run_ids[41] == "run-two", "A reused debugger session should record the new run token.")
	editor._system_message_received([&"RunFinished", "run-two", 0], 41)
	_assert_true(editor.test_has_exited_properly, "The reused session's exit message should complete the new run.")
	editor._logger_message_received(["run-two", "Default Logger", "Set Data", "source", "second"], 41)
	_assert_true(editor.logs.log_dictionary.has(next_test.get_identity_key()), "Messages after a reused session starts should belong to the new test.")

	var startup_probe := StartupProbe.new()
	root.add_child(startup_probe)
	startup_probe.run_started = true
	_assert_true(await startup_probe._wait_until_run_starts(1), "An acknowledged runtime startup should complete the startup handshake.")
	startup_probe.run_started = false
	startup_probe.simulated_game_running = true
	_assert_true(!await startup_probe._wait_until_run_starts(1), "A runtime that never acknowledges startup should time out.")
	startup_probe.queue_free()

	editor.currently_running_test = next_test
	editor.current_test_run_id = 2
	editor._record_current_run_failure("startup validation failure")
	_assert_true(!editor._test_passed(next_test), "An editor-detected startup failure should fail the test.")
	editor.current_run_failure_message = ""

	editor.running_test_series = true
	editor.test_has_exited_properly = false
	next_test.premature_end_is_error = false
	_assert_true(!editor._should_cancel_series_after_test(next_test), "An allowed direct exit should not cancel the remaining series.")
	next_test.premature_end_is_error = true
	_assert_true(editor._should_cancel_series_after_test(next_test), "An unexpected exit configured as an error should cancel the remaining series.")

	view.queue_free()
	editor.free()
	await process_frame
	if failures.is_empty():
		print("SERIES_BEHAVIOR_VALIDATION_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
