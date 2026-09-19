extends RefCounted
class_name AutoPlaySuiteInstructionSet_CustomTest

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Game] Kill" : AutoPlaySuiteInstructionDefinition.Create(_kill, "Make a person kill someone in the game"),
	&"[Game] Make Love" : AutoPlaySuiteInstructionDefinition.Create(_make_love, "Make two people make love in the game"),
	&"[Game] Kill < X, Love >= X" : AutoPlaySuiteInstructionDefinition.Create(_kill_or_love, "Gamble!"),
	&"[Game] Play Forever, K<X, L>X" : AutoPlaySuiteInstructionDefinition.Create(_start_kill_or_love_forever, "Gamble forever", _process_kill_or_love_forever),
	&"[Game] Exit On All Dead Or 10 Alive" : AutoPlaySuiteInstructionDefinition.Create(_enable_exit_on_condition, "Sets the game to exit if ever at 0 or 10 people"),
	&"[Game] Set Time Scale" : AutoPlaySuiteInstructionDefinition.Create(_set_time_scale, "Sets the engine's time scale"),
}

func hook_into_suite():
	AutoPlaySuiteActionLibrary.add_actions_to_library(instruction_dictionary)

func unhook_from_suite() -> void:
	if is_instance_valid(Game.Singleton) && Game.Singleton.signal_on_population_changed.is_connected(_on_population_changed):
		Game.Singleton.signal_on_population_changed.disconnect(_on_population_changed)

#region == Replace these with the actions unique to your game ==

func _kill(arguments : AutoPlaySuiteActionResource):
	if !is_instance_valid(Game.Singleton) || Game.Singleton.is_queued_for_deletion():
		arguments.fail("The Game singleton is unavailable.")
		return
	Game.Singleton._kill_random()
	if is_instance_valid(AutoPlaySuiteCustomLogger_AutoLog.Singleton) && !AutoPlaySuiteCustomLogger_AutoLog.Singleton.is_queued_for_deletion():
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Killed somebody!")
	arguments.finished = true

func _make_love(arguments : AutoPlaySuiteActionResource):
	if !is_instance_valid(Game.Singleton) || Game.Singleton.is_queued_for_deletion():
		arguments.fail("The Game singleton is unavailable.")
		return
	Game.Singleton._procreate_random()
	if is_instance_valid(AutoPlaySuiteCustomLogger_AutoLog.Singleton) && !AutoPlaySuiteCustomLogger_AutoLog.Singleton.is_queued_for_deletion():
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Created life!")
	arguments.finished = true

func _kill_or_love(arguments : AutoPlaySuiteActionResource):
	_perform_kill_or_love(arguments)
	arguments.finished = true

func _perform_kill_or_love(arguments : AutoPlaySuiteActionResource):
	if is_instance_valid(AutoPlaySuiteCustomLogger_AutoLog.Singleton) && !AutoPlaySuiteCustomLogger_AutoLog.Singleton.is_queued_for_deletion():
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Rolling the die, and...")
	
	if randf() < arguments.float_var:
		_kill(arguments)
	else:
		_make_love(arguments)

func _start_kill_or_love_forever(arguments : AutoPlaySuiteActionResource):
	if !is_instance_valid(Game.Singleton) || Game.Singleton.is_queued_for_deletion():
		arguments.fail("The Game singleton is unavailable.")
		return
	arguments.timeout_seconds = 0.0
	arguments.runtime_data[&"time_until_next_action"] = 0.0

func _process_kill_or_love_forever(delta : float, arguments : AutoPlaySuiteActionResource):
	var time_until_next : float = arguments.runtime_data.get(&"time_until_next_action", 0.0) - delta
	if time_until_next > 0.0:
		arguments.runtime_data[&"time_until_next_action"] = time_until_next
		return
	_perform_kill_or_love(arguments)
	arguments.finished = false
	arguments.runtime_data[&"time_until_next_action"] = 2.0

func _enable_exit_on_condition(arguments : AutoPlaySuiteActionResource):
	if !is_instance_valid(Game.Singleton) || Game.Singleton.is_queued_for_deletion():
		arguments.fail("The Game singleton is unavailable.")
		return
	if !Game.Singleton.signal_on_population_changed.is_connected(_on_population_changed):
		Game.Singleton.signal_on_population_changed.connect(_on_population_changed)
	arguments.finished = true
	_on_population_changed(Game.Singleton.people_alive.size())

func _on_population_changed(current_population : int):
	if current_population > 0 && current_population < 10:
		return
	if is_instance_valid(Game.Singleton) && Game.Singleton.signal_on_population_changed.is_connected(_on_population_changed):
		Game.Singleton.signal_on_population_changed.disconnect(_on_population_changed)
	if is_instance_valid(AutoPlaySuiteCustomLogger_AutoLog.Singleton) && !AutoPlaySuiteCustomLogger_AutoLog.Singleton.is_queued_for_deletion():
		if current_population == 0:
			AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Exited because all were dead!")
		else:
			AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Exited because paradise was achieved! Ten alive!")
	AutoPlaySuiteTestRunner.QuitGame()

func _set_time_scale(arguments : AutoPlaySuiteActionResource):
	Engine.time_scale = arguments.float_var
	arguments.finished = true


#endregion
