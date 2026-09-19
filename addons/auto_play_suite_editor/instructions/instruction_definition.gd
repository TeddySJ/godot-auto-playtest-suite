extends RefCounted
class_name AutoPlaySuiteInstructionDefinition

## Called once when the action becomes active. Avoid starting asynchronous work here
## when the action must be suspended cleanly by an interruption.
var on_enter : Callable
## Called only while the action is current, so ongoing interruptible work belongs here.
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
