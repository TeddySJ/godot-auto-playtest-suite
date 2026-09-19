@tool
extends Node
class_name AutoPlaySuiteActionLibrary

static var possible_actions : Dictionary[StringName, AutoPlaySuiteInstructionDefinition]
static var duplicate_action_ids : Dictionary[StringName, bool]

static func clear_library() -> void:
	possible_actions.clear()
	duplicate_action_ids.clear()

static func has_action(action_id : StringName) -> bool:
	return !duplicate_action_ids.has(action_id) && possible_actions.has(action_id) && possible_actions[action_id] != null

static func get_action(action_id : StringName) -> AutoPlaySuiteInstructionDefinition:
	if !has_action(action_id):
		return null
	return possible_actions[action_id]

static func add_actions_to_library(instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition]) -> void:
	for key : StringName in instruction_dictionary.keys():
		var definition := instruction_dictionary[key]
		if key.is_empty() || key == &"[UNSET]":
			push_error("Instruction sets cannot register an empty or [UNSET] action ID.")
			continue
		if definition == null || !definition.on_enter.is_valid() || !definition.on_process.is_valid():
			push_error("Action '%s' has an incomplete instruction definition." % key)
			continue
		if duplicate_action_ids.has(key):
			push_error("Action ID '%s' is registered by more than one instruction set and remains unavailable." % key)
			continue
		if possible_actions.has(key):
			possible_actions.erase(key)
			duplicate_action_ids[key] = true
			push_error("Action ID '%s' is registered by more than one instruction set and has been disabled." % key)
			continue
		possible_actions[key] = definition
