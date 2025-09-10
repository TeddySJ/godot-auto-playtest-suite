extends Node
class_name AutoPlaySuiteHookNode

static var initialized : bool = false

func _ready() -> void:
	if initialized:
		return
	
	if OS.get_environment("DoAutoTesting") == "true":
		AutoPlaySuiteTestRunner.start_testing()
		initialized = true
