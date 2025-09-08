extends Node

var callable_dictionary : Dictionary[StringName, InstructionDefinition] ={
	&"[Debug] Print String" : InstructionDefinition.Create(_action_debug_print_string, "Prints a string"),
	&"[Debug] Print Float" : InstructionDefinition.Create(_action_debug_print_float, "Prints a float"),
}

func hook_into_suite(suite : AutoTestingSuite):
	suite.possible_actions = callable_dictionary

#region == Replace these with the actions unique to your game ==

func _action_debug_print_string(arguments : AutoPlaySuiteActionResource):
	print(arguments.string_var)

func _action_debug_print_float(arguments : AutoPlaySuiteActionResource):
	print(arguments.float_var)

#endregion
