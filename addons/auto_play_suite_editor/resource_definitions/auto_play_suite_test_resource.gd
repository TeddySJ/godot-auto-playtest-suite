@tool
extends Resource
class_name AutoPlaySuiteTestResource

@export var test_name : String
@export var test_uid : String
@export var actions : Array[AutoPlaySuiteActionResource]
@export var post_actions : Array[AutoPlaySuiteActionResource]

@export var premature_end_is_error : bool = false

func get_validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if actions.is_empty():
		errors.append("The main action list is empty.")
	_append_action_validation_errors(actions, "main", errors)
	_append_action_validation_errors(post_actions, "post", errors)
	return errors

func _append_action_validation_errors(action_array : Array[AutoPlaySuiteActionResource], list_name : String, errors : PackedStringArray) -> void:
	for index in action_array.size():
		var action := action_array[index]
		if action == null:
			errors.append("The %s action at index %d is null." % [list_name, index])
			continue
		if !AutoPlaySuiteActionLibrary.has_action(action.action_id):
			errors.append("The %s action at index %d has an unknown action ID: %s" % [list_name, index, action.action_id])
