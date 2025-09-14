extends RefCounted
class_name AutoPlaySuiteInstructionSet_Default

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Debug] Print String" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_string, "Prints a string"),
	&"[Debug] Print Float" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_float, "Prints a float"),
	&"[Engine] Quit" : AutoPlaySuiteInstructionDefinition.Create(_action_exit_game, "Exits the game"),
	&"[Wait] Wait X Seconds" : AutoPlaySuiteInstructionDefinition.Create(_wait_x_seconds, "Waits for [float] seconds"),
	&"[Logging] Start Logger" : AutoPlaySuiteInstructionDefinition.Create(_start_logger, "Instances a logger of [string] class"),
	&"[Logging] Instruct Logger" : AutoPlaySuiteInstructionDefinition.Create(_instruct_logger, "Instructs an existing logger of [string] class"),
	&"[Eval] Start Evaluator" : AutoPlaySuiteInstructionDefinition.Create(_start_evaluator, "Instances an evaluator of [string] class"),
	&"[Eval] Make Evaluation" : AutoPlaySuiteInstructionDefinition.Create(_instruct_evaluator, "Instructs an existing evaluator. Syntax: '[class_name]:[instruction]'"),
}

func hook_into_suite():
	AutoPlaySuiteActionLibrary.add_actions_to_library(instruction_dictionary)

#region == Replace these with the actions unique to your game ==

func _action_debug_print_string(arguments : AutoPlaySuiteActionResource):
	print(arguments.string_var)
	arguments.finished = true

func _action_debug_print_float(arguments : AutoPlaySuiteActionResource):
	print(arguments.float_var)
	arguments.finished = true

func _action_exit_game(arguments : AutoPlaySuiteActionResource):
	arguments.finished = true
	await Engine.get_main_loop().create_timer(0.1).timeout
	AutoPlaySuiteTestRunner.QuitGame()

func _action_print_hi(arguments : AutoPlaySuiteActionResource):
	await Engine.get_main_loop().create_timer(arguments.float_var).timeout
	arguments.finished = true

func _action_process_print_hi(delta: float, arguments : AutoPlaySuiteActionResource):
	print("Hi! ", arguments.float_var, " seconds remaining...")
	arguments.float_var -= delta

func _start_logger(arguments : AutoPlaySuiteActionResource):
	arguments.finished = true
	var logger : AutoPlaySuiteLogger = AutoPlaySuiteLogger.instantiate_by_class_name(arguments.string_var)
	if logger == null:
		print("Failed to create logger of type: ", arguments.string_var)
		return
	
	Engine.get_main_loop().root.add_child.call_deferred(logger)

func _instruct_logger(arguments : AutoPlaySuiteActionResource):
	arguments.finished = true
	var logger : AutoPlaySuiteLogger = AutoPlaySuiteLogger.get_logger_by_class_name(arguments.string_var)
	if logger == null:
		print("Failed to get logger of type: ", arguments.string_var)
		return
	
	logger._on_instruction(arguments)

func _start_evaluator(arguments : AutoPlaySuiteActionResource):
	arguments.finished = true
	var evaluator : AutoPlaySuiteEvaluator = AutoPlaySuiteEvaluator.instantiate_by_class_name(arguments.string_var)
	if evaluator == null:
		print("Failed to create evaluator of type: ", arguments.string_var)
		return
	
	Engine.get_main_loop().root.add_child.call_deferred(evaluator)

func _instruct_evaluator(arguments : AutoPlaySuiteActionResource):
	arguments.finished = true
	var strings : PackedStringArray = arguments.string_var.split(":")
	var evaluator : AutoPlaySuiteEvaluator = AutoPlaySuiteEvaluator.get_evaluator_by_class_name(strings[0])
	if evaluator == null:
		print("Failed to get evaluator of type: ", strings[0])
		return
	
	evaluator._on_instruction(arguments)


func _wait_x_seconds(arguments : AutoPlaySuiteActionResource):
	await Engine.get_main_loop().create_timer(arguments.float_var).timeout
	arguments.finished = true

#endregion
