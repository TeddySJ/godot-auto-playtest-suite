extends Node2D
class_name Game

func _ready() -> void:
	if OS.get_environment("DoAutoTesting") == "true":
		AutoPlaySuiteTestRunner.start_testing()
