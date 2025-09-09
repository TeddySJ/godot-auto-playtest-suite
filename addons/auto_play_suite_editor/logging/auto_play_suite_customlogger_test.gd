extends AutoPlaySuiteLogger
class_name AutoPlaySuiteCustomLogger_Test

var time_passed : float = 0

func setup():
	forward_output_to_editor = true
	logger_name = "Test"
	write_to_output("Created a Test Logger!")

func _process(delta: float) -> void:
	time_passed += delta
	if time_passed >= 1:
		write_to_output("A second has passed!")
		time_passed -= 1

func _on_auto_play_action(resource : AutoPlaySuiteActionResource):
	if resource.float_var == 0:
		write_to_output("It was like this!")
	else:
		write_to_output("It was like that!")
	
