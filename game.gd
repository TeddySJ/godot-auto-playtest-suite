extends Node2D
class_name Game

func _ready() -> void:
	if OS.get_environment("DoAutoTesting") == "true":
		var path := OS.get_environment("AutoTestPath")
		var test : AutoPlaySuiteTestResource = load(path)
		print(test.actions[0].string_var)
