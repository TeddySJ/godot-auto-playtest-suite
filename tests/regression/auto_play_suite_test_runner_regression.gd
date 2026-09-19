extends SceneTree

const ACTION_FAIL := &"[Regression] Fail"
const ACTION_HOLD := &"[Regression] Hold"
const ACTION_INTERRUPT := &"[Regression] Interrupt"
const ACTION_POST_ONE := &"[Regression] Post One"
const ACTION_POST_TWO := &"[Regression] Post Two"
const ACTION_TIMEOUT := &"[Regression] Timeout"

var failures : int = 0
var trace : Array[String] = []

class RecordingRunner extends AutoPlaySuiteTestRunner:
	var recorded_exit_code : int = -1
	var recorded_system_messages : Array[Array] = []

	func _send_system_message(data : Array) -> void:
		recorded_system_messages.append(data)

	func _quit_after_debugger_flush(exit_code : int) -> void:
		recorded_exit_code = exit_code

class InstructionTeardownProbe extends RefCounted:
	var unhook_count : int = 0

	func unhook_from_suite() -> void:
		unhook_count += 1

class GameSingletonProbe extends Game:
	func _ready() -> void:
		Singleton = self

func _initialize() -> void:
	OS.set_environment("AutoTestRunToken", "runner-regression")
	_run_regressions.call_deferred()

func _run_regressions() -> void:
	_register_regression_actions()
	_test_unexpected_end_is_an_error_by_default()
	_test_nonzero_runtime_exit_fails_without_evaluation_log()
	_test_failed_main_action_runs_post_actions()
	_test_invalid_main_action_runs_post_actions()
	_test_timed_out_main_action_runs_post_actions()
	_test_normal_quit_runs_post_actions_with_zero_exit()
	_test_failed_post_action_continues_cleanup()
	_test_reused_interrupt_drops_runtime_state()
	_test_runner_singleton_recovers_after_free()
	_test_default_logger_singleton_clears_on_exit()
	_test_runtime_registries_drop_exited_nodes()
	_test_runtime_registry_cleanup_resets_state()
	_test_instruction_reload_unhooks_previous_instances()
	_test_evaluator_aliases_share_one_registry_entry()
	_test_demo_game_singleton_clears_on_exit()

	if failures == 0:
		print("AUTO_PLAY_SUITE_RUNNER_REGRESSION: PASS")
	else:
		push_error("AUTO_PLAY_SUITE_RUNNER_REGRESSION: %d failure(s)" % failures)
	OS.set_environment("AutoTestRunToken", "")
	quit(failures)

func _test_unexpected_end_is_an_error_by_default() -> void:
	var test := AutoPlaySuiteTestResource.new()
	_expect(test.premature_end_is_error, "Unexpected test termination should be an error by default.")

func _test_nonzero_runtime_exit_fails_without_evaluation_log() -> void:
	var editor := AutoPlaySuite.new()
	editor.logs = AutoPlaySuiteLogStore.new()
	editor.received_exit_message = true
	editor.current_test_exit_code = 1
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = "NonzeroExit"
	_expect(!editor._test_passed(test), "A nonzero runtime exit should fail without relying on an evaluation log.")
	editor.free()

func _register_regression_actions() -> void:
	AutoPlaySuiteActionLibrary.clear_library()
	var definitions : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] = {
		ACTION_FAIL: AutoPlaySuiteInstructionDefinition.Create(_enter_fail),
		ACTION_HOLD: AutoPlaySuiteInstructionDefinition.Create(_enter_hold),
		ACTION_INTERRUPT: AutoPlaySuiteInstructionDefinition.Create(_enter_interrupt),
		ACTION_POST_ONE: AutoPlaySuiteInstructionDefinition.Create(_enter_post_one),
		ACTION_POST_TWO: AutoPlaySuiteInstructionDefinition.Create(_enter_post_two),
		ACTION_TIMEOUT: AutoPlaySuiteInstructionDefinition.Create(_enter_timeout),
	}
	AutoPlaySuiteActionLibrary.add_actions_to_library(definitions)

func _test_failed_main_action_runs_post_actions() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([ACTION_FAIL], [ACTION_POST_ONE, ACTION_POST_TWO])
	runner._start_test(test)
	_tick_runner(runner, 3)

	_expect(trace == ["fail", "post_one", "post_two"], "A failed main action should run all post-actions in order.")
	_expect(runner.post_actions_has_been_ran, "A failed main action should mark post-actions as run.")
	_expect(runner.recorded_exit_code == 1, "A failed main action should retain a nonzero exit code after post-actions.")
	_destroy_runner(runner)

func _test_invalid_main_action_runs_post_actions() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([&"[Regression] Unknown"], [ACTION_POST_ONE])
	runner._start_test(test)
	_tick_runner(runner, 1)

	_expect(trace == ["post_one"], "An invalid main action should still run valid post-actions.")
	_expect(runner.recorded_exit_code == 1, "An invalid main action should retain a nonzero exit code after post-actions.")
	_destroy_runner(runner)

func _test_timed_out_main_action_runs_post_actions() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([ACTION_TIMEOUT], [ACTION_POST_ONE])
	runner._start_test(test)
	runner.current_action.elapsed_seconds = runner.current_action.timeout_seconds
	_tick_runner(runner, 2)

	_expect(trace == ["timeout", "post_one"], "A timed-out main action should still run post-actions.")
	_expect(runner.recorded_exit_code == 1, "A timed-out main action should retain a nonzero exit code after post-actions.")
	_destroy_runner(runner)

func _test_normal_quit_runs_post_actions_with_zero_exit() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([ACTION_HOLD], [ACTION_POST_ONE, ACTION_POST_TWO])
	runner._start_test(test)
	AutoPlaySuiteTestRunner.QuitGame()
	_tick_runner(runner, 2)

	_expect(trace == ["hold", "post_one", "post_two"], "A normal quit should run all post-actions in order.")
	_expect(runner.recorded_exit_code == 0, "A normal quit should retain a zero exit code after post-actions.")
	_expect(runner.recorded_system_messages.has([&"RunFinished", "runner-regression", 0]), "A normal quit should report its run token and zero exit code.")
	_destroy_runner(runner)

func _test_failed_post_action_continues_cleanup() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([ACTION_HOLD], [ACTION_FAIL, ACTION_POST_TWO])
	runner._start_test(test)
	AutoPlaySuiteTestRunner.QuitGame()
	_tick_runner(runner, 2)

	_expect(trace == ["hold", "fail", "post_two"], "A failed post-action should not prevent later cleanup post-actions.")
	_expect(runner.recorded_exit_code == 1, "A failed post-action should change the final exit code to nonzero.")
	_expect(runner.recorded_system_messages.has([&"RunFinished", "runner-regression", 1]), "A failed test should report its run token and nonzero exit code.")
	_destroy_runner(runner)

func _test_reused_interrupt_drops_runtime_state() -> void:
	trace.clear()
	var runner := _create_runner()
	var test := _create_test([ACTION_HOLD], [])
	runner._start_test(test)

	var reused_action := _create_action(ACTION_INTERRUPT)
	reused_action.entered = true
	reused_action.finished = true
	reused_action.failed = true
	reused_action.failure_message = "stale failure"
	reused_action.elapsed_seconds = 999.0
	reused_action.runtime_data[&"stale"] = true
	runner.interrupt_with_this_action(reused_action)

	var interrupt_copy := runner.current_action
	_expect(interrupt_copy != reused_action, "An injected action should be duplicated before execution.")
	_expect(interrupt_copy.entered, "The duplicated interrupt should enter normally.")
	_expect(!interrupt_copy.finished, "The duplicated interrupt should not retain a stale finished state.")
	_expect(!interrupt_copy.failed, "The duplicated interrupt should not retain a stale failure state.")
	_expect(interrupt_copy.failure_message.is_empty(), "The duplicated interrupt should not retain a stale failure message.")
	_expect(interrupt_copy.elapsed_seconds == 0.0, "The duplicated interrupt should not retain elapsed runtime.")
	_expect(interrupt_copy.runtime_data.is_empty(), "The duplicated interrupt should not retain runtime data.")
	_destroy_runner(runner)

func _test_runner_singleton_recovers_after_free() -> void:
	var first_runner := _create_runner()
	first_runner.free()
	_expect(AutoPlaySuiteTestRunner.Singleton == null, "Freeing the runner should clear its singleton reference.")
	var replacement := AutoPlaySuiteTestRunner.instance()
	_expect(is_instance_valid(replacement), "The runner singleton should be recreated after the previous runner is freed.")
	_expect(AutoPlaySuiteTestRunner.Singleton == replacement, "The replacement runner should become the singleton.")
	_destroy_runner(replacement)

func _test_default_logger_singleton_clears_on_exit() -> void:
	var logger := AutoPlaySuiteDefaultLogger.new()
	root.add_child(logger)
	_expect(AutoPlaySuiteDefaultLogger.Singleton == logger, "A ready default logger should become the singleton.")
	logger.free()
	_expect(AutoPlaySuiteDefaultLogger.Singleton == null, "Freeing the default logger should clear its singleton reference.")

func _test_runtime_registries_drop_exited_nodes() -> void:
	var logger := AutoPlaySuiteLogger.new()
	AutoPlaySuiteLogger.CreatedLoggers["RegressionLogger"] = logger
	root.add_child(logger)
	logger.free()
	_expect(!AutoPlaySuiteLogger.CreatedLoggers.has("RegressionLogger"), "A logger leaving the tree should unregister itself.")
	var evaluator := AutoPlaySuiteEvaluator.new()
	AutoPlaySuiteEvaluator.CreatedEvaluators["RegressionEvaluator"] = evaluator
	root.add_child(evaluator)
	evaluator.free()
	_expect(!AutoPlaySuiteEvaluator.CreatedEvaluators.has("RegressionEvaluator"), "An evaluator leaving the tree should unregister itself.")

func _test_runtime_registry_cleanup_resets_state() -> void:
	var logger := AutoPlaySuiteLogger.new()
	AutoPlaySuiteLogger.CreatedLoggers["RegressionLogger"] = logger
	root.add_child(logger)
	var evaluator := AutoPlaySuiteEvaluator.new()
	AutoPlaySuiteEvaluator.CreatedEvaluators["RegressionEvaluator"] = evaluator
	root.add_child(evaluator)
	AutoPlaySuiteEvaluator.failed_evaluations = 3
	AutoPlaySuiteLogger.clear_created_loggers()
	AutoPlaySuiteEvaluator.clear_created_evaluators()
	_expect(AutoPlaySuiteLogger.CreatedLoggers.is_empty(), "Logger cleanup should clear the registry.")
	_expect(AutoPlaySuiteEvaluator.CreatedEvaluators.is_empty(), "Evaluator cleanup should clear the registry.")
	_expect(logger.is_queued_for_deletion(), "Logger cleanup should schedule registered nodes for deletion.")
	_expect(evaluator.is_queued_for_deletion(), "Evaluator cleanup should schedule registered nodes for deletion.")
	_expect(AutoPlaySuiteEvaluator.failed_evaluations == 0, "Evaluator cleanup should reset per-run failure numbering.")

func _test_instruction_reload_unhooks_previous_instances() -> void:
	var probe := InstructionTeardownProbe.new()
	AutoPlaySuiteInstructionLoader.refs = [probe]
	AutoPlaySuiteInstructionLoader.LoadAllInstructions()
	_expect(probe.unhook_count == 1, "Reloading instructions should unhook the previous instruction instances exactly once.")

func _test_evaluator_aliases_share_one_registry_entry() -> void:
	AutoPlaySuiteEvaluator.clear_created_evaluators()
	var evaluator := AutoPlaySuiteEvaluator.instantiate_by_class_name("GameOfLife")
	_expect(evaluator != null, "The evaluator should be creatable through its short name.")
	_expect(AutoPlaySuiteEvaluator.get_evaluator_by_class_name("AutoPlaySuiteCustomEvaluator_GameOfLife") == evaluator, "The full evaluator name should resolve the short-name instance.")
	_expect(AutoPlaySuiteEvaluator.instantiate_by_class_name("AutoPlaySuiteCustomEvaluator_GameOfLife") == null, "The full evaluator name should not create a second instance.")
	AutoPlaySuiteEvaluator.clear_created_evaluators()

func _test_demo_game_singleton_clears_on_exit() -> void:
	var game := GameSingletonProbe.new()
	root.add_child(game)
	_expect(Game.Singleton == game, "A ready game should become the demo singleton.")
	game.free()
	_expect(Game.Singleton == null, "Freeing the game should clear the demo singleton.")

func _create_runner() -> RecordingRunner:
	var runner := RecordingRunner.new()
	root.add_child(runner)
	return runner

func _destroy_runner(runner : AutoPlaySuiteTestRunner) -> void:
	runner.free()

func _create_test(main_action_ids : Array[StringName], post_action_ids : Array[StringName]) -> AutoPlaySuiteTestResource:
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = "RunnerRegression"
	for action_id in main_action_ids:
		test.actions.append(_create_action(action_id))
	for action_id in post_action_ids:
		test.post_actions.append(_create_action(action_id))
	return test

func _create_action(action_id : StringName) -> AutoPlaySuiteActionResource:
	return AutoPlaySuiteActionResource.Create(action_id)

func _tick_runner(runner : RecordingRunner, count : int) -> void:
	for index in count:
		if runner.is_quitting:
			return
		runner._process(0.016)

func _expect(condition : bool, message : String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)

func _enter_fail(action : AutoPlaySuiteActionResource) -> void:
	trace.append("fail")
	action.fail("expected regression failure")

func _enter_hold(action : AutoPlaySuiteActionResource) -> void:
	trace.append("hold")
	action.timeout_seconds = 0.0

func _enter_interrupt(action : AutoPlaySuiteActionResource) -> void:
	trace.append("interrupt")

func _enter_post_one(action : AutoPlaySuiteActionResource) -> void:
	trace.append("post_one")
	action.finished = true

func _enter_post_two(action : AutoPlaySuiteActionResource) -> void:
	trace.append("post_two")
	action.finished = true

func _enter_timeout(action : AutoPlaySuiteActionResource) -> void:
	trace.append("timeout")
	action.timeout_seconds = 0.1
