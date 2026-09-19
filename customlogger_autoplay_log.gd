extends AutoPlaySuiteLogger
class_name AutoPlaySuiteCustomLogger_Test

static var data_store : Dictionary = {}

var time_passed : float = 0
var game : Game

var people_last : int = 0

func setup():
	forward_output_to_editor = true
	logger_name = "Logger of Life"
	write_to_output("Created Logger!")
	_connect_to_current_game()
	if !is_instance_valid(game):
		return
	var participants : String = "Participants: "
	for person in game.people_alive:
		participants += str(person, " ")
	write_to_output(participants)

func _exit_tree() -> void:
	_disconnect_from_game()
	super._exit_tree()

func _connect_to_current_game() -> void:
	var current_game := Game.Singleton
	if !is_instance_valid(current_game) || current_game.is_queued_for_deletion() || current_game == game:
		return
	_disconnect_from_game()
	game = current_game
	people_last = game.people_alive.size()
	if !game.signal_on_write_to_log.is_connected(_on_game_message):
		game.signal_on_write_to_log.connect(_on_game_message)

func _disconnect_from_game() -> void:
	if is_instance_valid(game) && game.signal_on_write_to_log.is_connected(_on_game_message):
		game.signal_on_write_to_log.disconnect(_on_game_message)
	game = null

func _on_game_message(message : String):
	write_to_output(message)
	if game.people_alive.size() != people_last:
		people_last = game.people_alive.size()
		write_to_output(str("Now there are ", people_last, " people left!"))
		

func _process(delta: float) -> void:
	if !is_instance_valid(game) || game != Game.Singleton:
		_connect_to_current_game()

func _on_instruction(action_resource : AutoPlaySuiteActionResource):
	if action_resource.float_var == 0:
		write_to_output("It was like this!")
	else:
		write_to_output("It was like that!")
	
