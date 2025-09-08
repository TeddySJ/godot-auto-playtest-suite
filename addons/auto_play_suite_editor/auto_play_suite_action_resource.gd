extends Resource
class_name AutoPlaySuiteActionResource

@export var action_id : StringName = &""
@export var float_var : float = 0
@export var string_var : String = ""
@export var extra_vars : Array[String]

var finished : bool = false

static func Create(action_id : StringName, float_var : float = 0, string_var : String = "", extra_vars : Array[String] = []):
	var ret = AutoPlaySuiteActionResource.new()
	
	ret.action_id = action_id
	ret.float_var = float_var
	ret.string_var = string_var
	ret.extra_vars = extra_vars
	
	return ret
