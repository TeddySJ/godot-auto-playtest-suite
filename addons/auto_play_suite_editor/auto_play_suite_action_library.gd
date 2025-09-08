@tool
extends Node
class_name AutoPlaySuiteActionLibrary

static var possible_actions : Dictionary[StringName, AutoPlaySuiteInstructionDefinition]

static func add_actions_to_library(instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition]):
	for key : StringName in instruction_dictionary.keys():
		possible_actions[key] = instruction_dictionary[key]
