@tool
extends Resource
class_name AutoPlaySuiteActionResource

@export var action_id : StringName = &""
@export var float_var : float = 0
@export var string_var : String = ""
@export var extra_vars : Array[String]
## Maximum wall-clock time for this action. Set to 0 to allow it to run indefinitely.
@export var timeout_seconds : float = 60.0

var finished : bool = false
var entered : bool = false
var elapsed_seconds : float = 0.0
var failed : bool = false
var failure_message : String = ""
var runtime_data : Dictionary = {}

static func Create(action_id : StringName, float_var : float = 0, string_var : String = "", extra_vars : Array[String] = [], timeout_seconds : float = 60.0):
	var ret = AutoPlaySuiteActionResource.new()
	
	ret.action_id = action_id
	ret.float_var = float_var
	ret.string_var = string_var
	ret.extra_vars = extra_vars
	ret.timeout_seconds = timeout_seconds
	
	return ret

static func CreateEmpty() -> AutoPlaySuiteActionResource:
	var ret = AutoPlaySuiteActionResource.new()
	ret.action_id = "[UNSET]"
	return ret

func fail(message : String) -> void:
	failed = true
	failure_message = message
	finished = true
