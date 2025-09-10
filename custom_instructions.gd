extends RefCounted
class_name AutoPlaySuiteInstructionSet_CustomTest

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Custom] Print Secret" : AutoPlaySuiteInstructionDefinition.Create(_action_debug_print_secret, "Prints a secret"),
}

func hook_into_suite():
	AutoPlaySuiteActionLibrary.add_actions_to_library(instruction_dictionary)

#region == Replace these with the actions unique to your game ==

func _action_debug_print_secret(arguments : AutoPlaySuiteActionResource):
	print("Hemligt: ", arguments.string_var)
	arguments.finished = true

#endregion
