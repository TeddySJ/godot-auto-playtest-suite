extends RefCounted
class_name AutoPlaySuiteInstructionSet_CustomTest

var instruction_dictionary : Dictionary[StringName, AutoPlaySuiteInstructionDefinition] ={
	&"[Game] Kill" : AutoPlaySuiteInstructionDefinition.Create(_kill, "Make a person kill someone in the game"),
	&"[Game] Make Love" : AutoPlaySuiteInstructionDefinition.Create(_make_love, "Make two people make love in the game"),
	&"[Game] Kill < X, Love >= X" : AutoPlaySuiteInstructionDefinition.Create(_kill_or_love, "Gamble!"),
	&"[Game] Play Forever, K<X, L>X" : AutoPlaySuiteInstructionDefinition.Create(_kill_or_love_forever, "Gamble!"),
	&"[Game] Exit On All Dead Or 10 Alive" : AutoPlaySuiteInstructionDefinition.Create(_exit_on_condition, "Sets the game to exit if ever at 0 or 10 people"),
	&"[Game] Set Time Scale" : AutoPlaySuiteInstructionDefinition.Create(_set_time_scale, "Sets the engine's time scale"),
}

func hook_into_suite():
	AutoPlaySuiteActionLibrary.add_actions_to_library(instruction_dictionary)

#region == Replace these with the actions unique to your game ==

func _kill(arguments : AutoPlaySuiteActionResource):
	Game.Singleton._kill_random()
	if AutoPlaySuiteCustomLogger_AutoLog.Singleton:
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Killed somebody!")
	arguments.finished = true

func _make_love(arguments : AutoPlaySuiteActionResource):
	Game.Singleton._procreate_random()
	if AutoPlaySuiteCustomLogger_AutoLog.Singleton:
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Created life!")
	arguments.finished = true

func _kill_or_love(arguments : AutoPlaySuiteActionResource):
	
	if AutoPlaySuiteCustomLogger_AutoLog.Singleton:
		AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Rolling the die, and...")
	
	if randf() < arguments.float_var:
		_kill(arguments)
	else:
		_make_love(arguments)
		
	arguments.finished = true
	
func _kill_or_love_forever(arguments : AutoPlaySuiteActionResource):
	_kill_or_love(arguments)
	Engine.get_main_loop().create_timer(2).timeout.connect(_kill_or_love_forever.bind(arguments))
	
func _exit_on_condition(arguments : AutoPlaySuiteActionResource):
	print("Exit on condition?")
	if Game.Singleton.people_alive.size() == 0:
		if AutoPlaySuiteCustomLogger_AutoLog.Singleton:
			AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Exited because all were dead!")
		Engine.get_main_loop().create_timer(10).timeout.connect(AutoPlaySuiteTestRunner.QuitGame)
		return
	elif Game.Singleton.people_alive.size() >= 10:
		if AutoPlaySuiteCustomLogger_AutoLog.Singleton:
			AutoPlaySuiteCustomLogger_AutoLog.Singleton.write_to_output("Exited because paradise was achieved! Ten alive!")
		AutoPlaySuiteTestRunner.QuitGame()
		return

	arguments.finished = true
	Engine.get_main_loop().create_timer(1).timeout.connect(_exit_on_condition.bind(arguments))

func _set_time_scale(arguments : AutoPlaySuiteActionResource):
	Engine.time_scale = arguments.float_var
	arguments.finished = true


#endregion
