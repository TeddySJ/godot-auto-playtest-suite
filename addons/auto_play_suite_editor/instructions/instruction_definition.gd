extends RefCounted
class_name AutoPlaySuiteInstructionDefinition

## Called once when the action becomes active. Avoid starting asynchronous work here
## when the action must be suspended cleanly by an interruption.
var on_enter : Callable
## Called only while the action is current, so ongoing interruptible work belongs here.
var on_process : Callable
var description : String
## Optional background color for this instruction's rows in the action lists.
## Transparent leaves the editor theme's background unchanged.
var list_background_color : Color = Color.TRANSPARENT

static func EmptyProcess(delta : float, action_resource : AutoPlaySuiteActionResource):
	pass

static func Create(on_enter : Callable, description : String = "", on_process : Callable = EmptyProcess, list_background_color : Color = Color.TRANSPARENT) -> AutoPlaySuiteInstructionDefinition:
	var ret = AutoPlaySuiteInstructionDefinition.new()
	
	ret.on_enter = on_enter
	ret.on_process = on_process
	ret.description = description
	ret.list_background_color = list_background_color
	
	return ret
