extends Node
class_name AutoPlaySuiteTestRunner

static var engine_speed_multiplier : float = 1
static var Singleton : AutoPlaySuiteTestRunner

var tests_are_running: bool:
	get:
		return current_action != null

var test_resource : AutoPlaySuiteTestResource

var actions_to_do : Array[AutoPlaySuiteActionResource] = []

var current_action : AutoPlaySuiteActionResource

var current_action_instruction : AutoPlaySuiteInstructionDefinition

var post_actions_has_been_ran : bool = false
var is_quitting : bool = false
var quit_requested : bool = false
var running_post_actions : bool = false
var last_process_ticks_msec : int = 0
var exit_code_after_post_actions : int = 0
var run_token : String = ""
var run_finished : bool = false
var registered_debugger_capture : bool = false

func _ready() -> void:
	Singleton = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	if EngineDebugger.is_active() && !EngineDebugger.has_capture(&"aps"):
		EngineDebugger.register_message_capture(&"aps", _capture_debugger_message)
		registered_debugger_capture = true

func _exit_tree() -> void:
	if Singleton != self:
		return
	Singleton = null
	if registered_debugger_capture && EngineDebugger.has_capture(&"aps"):
		EngineDebugger.unregister_message_capture(&"aps")
	AutoPlaySuiteHookNode.initialized = false
	_clear_test_services()

func _start_test(test : AutoPlaySuiteTestResource):
	is_quitting = false
	quit_requested = false
	running_post_actions = false
	post_actions_has_been_ran = false
	exit_code_after_post_actions = 0
	run_finished = false
	run_token = OS.get_environment("AutoTestRunToken")
	_send_system_message([&"RunStarted", run_token])
	test_resource = null
	if test == null:
		_fail_test("Cannot start a null test resource.")
		return
	test_resource = test.duplicate()
	var validation_errors := test_resource.get_validation_errors()
	if !validation_errors.is_empty():
		_fail_test("Invalid test resource: %s" % "; ".join(validation_errors))
		return
	_populate_action_array_from_other_array(test_resource.actions)
	_progress_testing()

func _restart_current_test():
	_clear_test_services()
	_create_default_logger()
	_start_test(test_resource)

func _populate_action_array_from_other_array(array : Array[AutoPlaySuiteActionResource]):
	actions_to_do.clear()
	for action in array:
		actions_to_do.append(action.duplicate())

func _process(delta: float) -> void:
	if current_action != null && !is_quitting:
		var processing_action := current_action
		var processing_instruction := current_action_instruction
		var current_ticks := Time.get_ticks_msec()
		processing_action.elapsed_seconds += float(current_ticks - last_process_ticks_msec) / 1000.0
		last_process_ticks_msec = current_ticks
		processing_instruction.on_process.call(delta, processing_action)
		if is_quitting || current_action != processing_action:
			return
		if processing_action.failed:
			var failure_details := processing_action.failure_message
			if failure_details.is_empty():
				failure_details = "The action reported a failure without details."
			_fail_test("Action '%s' failed: %s" % [processing_action.action_id, failure_details])
		elif processing_action.finished:
			_progress_testing()
		elif processing_action.timeout_seconds > 0.0 && processing_action.elapsed_seconds >= processing_action.timeout_seconds:
			_fail_test("Action '%s' timed out after %.1f seconds." % [processing_action.action_id, processing_action.timeout_seconds])

## Injects a high-priority action and suspends the current action's on_process callback.
## Work already started asynchronously by on_enter cannot be suspended by the runner.
## Interruptible actions should keep their ongoing work in on_process.
func interrupt_with_this_action(action_resource : AutoPlaySuiteActionResource):
	if !tests_are_running:
		return
	if action_resource == null:
		push_error("Cannot interrupt with a null action resource.")
		return
	if !AutoPlaySuiteActionLibrary.has_action(action_resource.action_id):
		push_error("Cannot interrupt with unknown action: %s" % action_resource.action_id)
		return
	
	var interrupting_action : AutoPlaySuiteActionResource = action_resource.duplicate()
	interrupting_action.entered = false
	interrupting_action.finished = false
	actions_to_do.insert(0, current_action)
	current_action = interrupting_action
	_run_current_action()

func _run_current_action():
	if current_action == null:
		_fail_test("Cannot run a null action.")
		return
	current_action_instruction = AutoPlaySuiteActionLibrary.get_action(current_action.action_id)
	if current_action_instruction == null:
		_fail_test("Unknown action ID: %s" % current_action.action_id)
		return
	last_process_ticks_msec = Time.get_ticks_msec()
	if !current_action.entered:
		current_action.entered = true
		current_action_instruction.on_enter.call(current_action)

func _fail_test(message : String) -> void:
	if is_quitting || run_finished:
		return
	exit_code_after_post_actions = 1
	push_error(message)
	current_action = null
	AutoPlaySuiteEvaluator.log_failed_evaluation(message)
	if test_resource != null && test_resource.stop_series_on_error:
		return
	if running_post_actions:
		_progress_testing()
		return
	actions_to_do.clear()
	if has_post_actions() && !post_actions_has_been_ran:
		run_post_actions()
	else:
		_finish_current_test()

func _progress_testing():
	if actions_to_do.size() > 0:
		current_action = actions_to_do[0]
		actions_to_do.remove_at(0)
		_run_current_action()
	else:
		if running_post_actions:
			_finish_post_actions()
		else:
			_end_current_test()

func _end_current_test():
	if has_post_actions() && !post_actions_has_been_ran:
		run_post_actions()
	else:
		_finish_current_test()

func _testing_finished():
	print("Testing finished!")
	engine_speed_multiplier = 1
	current_action = null
	actions_to_do = []

func has_post_actions():
	return test_resource != null && test_resource.post_actions.size() > 0

func run_post_actions():
	if post_actions_has_been_ran:
		return
	post_actions_has_been_ran = true
	running_post_actions = true
	print("Post Actions: ", test_resource.post_actions.size())
	_populate_action_array_from_other_array(test_resource.post_actions)
	current_action = null
	_progress_testing()

func _finish_post_actions() -> void:
	running_post_actions = false
	_finish_current_test()

func _finish_current_test() -> void:
	if run_finished:
		return
	_testing_finished()
	if AutoPlaySuiteEvaluator.failed_evaluations > 0:
		exit_code_after_post_actions = 1
	var stop_after_failure := (
		test_resource != null
		&& test_resource.stop_series_on_error
		&& exit_code_after_post_actions != 0
	)
	if quit_requested || stop_after_failure:
		_quit_game(exit_code_after_post_actions)
	else:
		_finish_run(exit_code_after_post_actions, false)

func _quit_game(exit_code : int) -> void:
	if is_quitting || run_finished:
		return
	is_quitting = true
	_finish_run(exit_code, true)

func _finish_run(exit_code : int, will_quit : bool) -> void:
	if run_finished:
		return
	run_finished = true
	current_action = null
	actions_to_do.clear()
	_send_system_message([&"RunFinished", run_token, exit_code, will_quit])
	_clear_test_services()
	if will_quit:
		_quit_after_debugger_flush(exit_code)

func _on_failed_evaluation() -> void:
	if is_quitting || run_finished || test_resource == null || !test_resource.stop_series_on_error:
		return
	exit_code_after_post_actions = 1
	quit_requested = true
	current_action = null
	if running_post_actions:
		_progress_testing()
		return
	actions_to_do.clear()
	if has_post_actions() && !post_actions_has_been_ran:
		run_post_actions()
	else:
		_finish_current_test()

static func failed_evaluation_encountered() -> void:
	if is_instance_valid(Singleton) && !Singleton.is_queued_for_deletion():
		Singleton._on_failed_evaluation()

func _send_system_message(data : Array) -> void:
	EngineDebugger.send_message("aps:system", data)

func _quit_after_debugger_flush(exit_code : int) -> void:
	# Allow the final evaluation and system messages to reach the editor before
	# terminating the game process.
	await get_tree().process_frame
	get_tree().quit(exit_code)

static func start_testing():
	var path := OS.get_environment("AutoTestPath")
	var test : AutoPlaySuiteTestResource = load(path)
	_run_test.call_deferred(test)

static func _create_default_logger() -> void:
	var logger : AutoPlaySuiteLogger = AutoPlaySuiteLogger.get_default_logger()
	if logger == null:
		logger = AutoPlaySuiteLogger.instantiate_by_class_name("AutoPlaySuiteDefaultLogger")
	if logger != null && logger.get_parent() == null:
		Engine.get_main_loop().root.add_child.call_deferred(logger)

static func _clear_test_services() -> void:
	AutoPlaySuiteLogger.clear_created_loggers()
	AutoPlaySuiteEvaluator.clear_created_evaluators()

static func _run_test(test : AutoPlaySuiteTestResource):
	print("Starting Test")
	
	AutoPlaySuiteInstructionLoader.LoadAllInstructions()
	
	var test_runner := AutoPlaySuiteTestRunner.instance()
	_clear_test_services()
	_create_default_logger()
	test_runner._start_test(test)

func _capture_debugger_message(message : String, data : Array) -> bool:
	if message != "start_test":
		return false
	if data.size() < 2:
		push_error("Cannot start the next auto play test without a resource path and run token.")
		return true
	_start_test_from_debugger.call_deferred(str(data[0]), str(data[1]))
	return true

func _start_test_from_debugger(path : String, next_run_token : String) -> void:
	if tests_are_running || (!run_finished && test_resource != null):
		push_error("Cannot start another auto play test while one is still running.")
		return
	OS.set_environment("AutoTestPath", path)
	OS.set_environment("AutoTestRunToken", next_run_token)
	var next_test := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as AutoPlaySuiteTestResource
	_run_test(next_test)

static func QuitGame():
	if !is_instance_valid(Singleton) || Singleton.is_queued_for_deletion():
		Singleton = null
		push_error("Cannot quit an auto play test without an active test runner.")
		return
	if Singleton.quit_requested:
		return
	Singleton.quit_requested = true
	
	if Singleton.has_post_actions():
		Singleton.run_post_actions()
	else:
		Singleton._finish_current_test()

static func instance() -> AutoPlaySuiteTestRunner:
	if is_instance_valid(Singleton) && !Singleton.is_queued_for_deletion():
		return Singleton
	Singleton = null
	
	var instance := AutoPlaySuiteTestRunner.new()
	Engine.get_main_loop().root.add_child(instance)
	return instance
