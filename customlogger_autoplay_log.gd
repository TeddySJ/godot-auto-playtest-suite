extends AutoPlaySuiteLogger
class_name AutoPlaySuiteCustomLogger_Test

static var data_store : Dictionary = {}

var time_passed : float = 0
var game : Game

var people_last : int = 0

func setup():
	game = Game.Singleton
	people_last = game.people_alive.size()
	game.signal_on_write_to_log.connect(_on_game_message)
	forward_output_to_editor = true
	logger_name = "Logger of Life"
	write_to_output("Created Logger!")
	var participants : String = "Participants: "
	for person in Game.Singleton.people_alive:
		participants += str(person, " ")
	write_to_output(participants)

func _on_game_message(message : String):
	write_to_output(message)
	if game.people_alive.size() != people_last:
		people_last = game.people_alive.size()
		write_to_output(str("Now there are ", people_last, " people left!"))
		

func _process(delta: float) -> void:
	pass

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	if action_resource.float_var == 0:
		write_to_output("It was like this!")
	else:
		write_to_output("It was like that!")
	
