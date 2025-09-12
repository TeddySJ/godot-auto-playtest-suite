extends RefCounted
class_name AutoPlaySuiteInstructionDefinition

var on_enter : Callable
var on_process : Callable
var description : String

static func EmptyProcess(delta : float, action_resource : AutoPlaySuiteActionResource):
	pass

static func Create(on_enter : Callable, description : String = "", on_process : Callable = EmptyProcess):
	var ret = AutoPlaySuiteInstructionDefinition.new()
	
	ret.on_enter = on_enter
	ret.on_process = on_process
	ret.description = description
	
	return ret
