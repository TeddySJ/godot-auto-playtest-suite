extends Node

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Debug] Print String" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_string, "Prints a string"),
	&"[Debug] Print Float" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_float, "Prints a float"),
	&"[Debug] Quit" : AutoPlaySuiteInstructionDefinition.Create(_action_exit_game, "Exits the game"),
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

#endregion
