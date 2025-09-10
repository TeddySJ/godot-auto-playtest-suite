extends Node

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Debug] Print String" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_string, "Prints a string"),
	&"[Debug] Print Float" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_float, "Prints a float"),
	&"[Debug] Print Hi X Seconds" : AutoPlaySuiteInstructionDefinition.Create(_action_print_hi, "Prints 'Hi' every frame for [float] seconds", _action_process_print_hi),
	&"[Debug] Quit" : AutoPlaySuiteInstructionDefinition.Create(_action_exit_game, "Exits the game"),
	&"[Logging] Start Logger" : AutoPlaySuiteInstructionDefinition.Create(_start_logger, "Instances a logger of [string] class"),
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
	Engine.get_main_loop().quit()

func _action_print_hi(arguments : AutoPlaySuiteActionResource):
	await Engine.get_main_loop().create_timer(arguments.float_var).timeout
	arguments.finished = true

func _action_process_print_hi(delta: float, arguments : AutoPlaySuiteActionResource):
	print("Hi! ", arguments.float_var, " seconds remaining...")
	arguments.float_var -= delta

func _start_logger(arguments : AutoPlaySuiteActionResource):
	var logger : AutoPlaySuiteLogger = AutoPlaySuiteLogger.instantiate_by_class_name(arguments.string_var)
	if logger == null:
		return
	
	Engine.get_main_loop().root.add_child.call_deferred(logger)
	arguments.finished = true


#endregion
