extends Node2D
class_name Game

func _ready() -> void:
	if OS.get_environment("DoAutoTesting") == "true":
		var path := OS.get_environment("AutoTestPath")
		var test : AutoPlaySuiteTestResource = load(path)
		_run_test.call_deferred(test)

func _run_test(test : AutoPlaySuiteTestResource):
	print("Starting Test")
	
	# TODO: Centralize location pointing to all scripts with custom definitions
	var custom_instructions = load("res://addons/auto_play_suite_editor/custom_instructions/custom_auto_play_instructions.gd").new()
	custom_instructions.hook_into_suite()
	
	var test_runner := AutoPlaySuiteTestRunner.instance()
	test_runner._start_test(test)
