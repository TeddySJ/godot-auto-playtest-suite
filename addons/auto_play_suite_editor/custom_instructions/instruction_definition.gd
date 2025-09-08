extends RefCounted
class_name InstructionDefinition

var method : Callable
var description : String

static func Create(method : Callable, description : String = ""):
	var ret = InstructionDefinition.new()
	
	ret.method = method
	ret.description = description
	
	return ret
