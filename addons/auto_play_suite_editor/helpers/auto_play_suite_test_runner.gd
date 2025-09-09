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

func _ready() -> void:
	Singleton = self

func _start_test(test : AutoPlaySuiteTestResource):
	test_resource = test.duplicate()
	_populate_action_array_from_other_array(test_resource.actions)
	_progress_testing()

func _restart_current_test():
	_start_test(test_resource)

func _populate_action_array_from_other_array(array : Array[AutoPlaySuiteActionResource]):
	actions_to_do.clear()
	for action in array:
		actions_to_do.append(action.duplicate())

func _process(delta: float) -> void:
	if current_action != null:
		current_action_instruction.on_process.call(delta, current_action)
		if current_action.finished:
			_progress_testing()

## This is to be used in conjunction with external code that can inject the resource when game state requires it
func interrupt_with_this_action(action_resource : AutoPlaySuiteActionResource):
	if !tests_are_running:
		return
	
	var action_instruction : AutoPlaySuiteInstructionDefinition = AutoPlaySuiteActionLibrary.possible_actions[action_resource.action_id]
	actions_to_do.insert(0, action_resource)
	_run_current_action()

func _run_current_action():
	_run_action(current_action)

func _run_action(action_resource : AutoPlaySuiteActionResource):
	current_action_instruction = AutoPlaySuiteActionLibrary.possible_actions[action_resource.action_id]
	current_action_instruction.on_enter.call(action_resource)

func _progress_testing():
	if actions_to_do.size() > 0:
		current_action = actions_to_do[0]
		actions_to_do.remove_at(0)
		_run_current_action()
	else:
		_end_current_test()

func _end_current_test():
	_testing_finished()

func _testing_finished():
	print("Testing finished!")
	engine_speed_multiplier = 1
	current_action = null
	actions_to_do = []

static func instance() -> AutoPlaySuiteTestRunner:
	if Singleton != null:
		return Singleton
	
	var instance := AutoPlaySuiteTestRunner.new()
	Engine.get_main_loop().root.add_child(instance)
	return instance
