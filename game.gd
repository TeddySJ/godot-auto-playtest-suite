extends Node2D
class_name Game

static var Singleton : Game

@export var labels : Array[Label]
@export var revenge_chance : float = 0.25

var names : Array[String] = ["Adam", "Bettan", "Caroline", "Danielle", "Erik", "Fred", "Göran", "Hanna", "Isak", "Jochen", "Kajsa", "Kim", "Linus", "Markus", "Nina", "Ola", "Per", "Quissling", "Robban", "Ulf", "Teddy", "Vilya"]

var log : Array[String]

var unused_names : Array[String] = []

var people_alive : Array[String] = []

var waiting_for_messages : int = 0

signal signal_on_write_to_log(message)

func _ready() -> void:
	Singleton = self
	
	for label in labels:
		label.visible = false
	
	unused_names.append_array(names)
	
	var peeps : String = ""
	var number_at_start : int = 3
	for n in number_at_start:
		var name := _get_unused_name()
		peeps += str(name)
		if n < number_at_start - 2:
			peeps += ", "
		elif n == number_at_start - 2:
			peeps += " och "
		people_alive.append(name)
	_write_to_log(str("Det var en gång ", peeps))

func _write_to_log(message : String):
	waiting_for_messages = max(0, waiting_for_messages - 1)
	log.push_front(message)
	if log.size() > labels.size():
		log.pop_back()
	_update_labels()
	signal_on_write_to_log.emit(message)

func _write_to_log_with_delay(message : String, delay : float):
	waiting_for_messages += 1
	get_tree().create_timer(delay).timeout.connect(_write_to_log.bind(message))

func _update_labels():
	for n in log.size():
		labels[n].visible = true
		labels[n].text = log[n]

func _process(delta: float) -> void:
	
	if waiting_for_messages > 0:
		return
	if Input.is_action_just_pressed("One"):
		_kill_random()
	elif Input.is_action_just_pressed("Two"):
		_procreate_random()

func _kill_random():
	if people_alive.size() == 0:
		return
	
	if people_alive.size() == 1:
		var person : String = people_alive[0]
		_write_to_log(str(person, " tog sitt eget liv."))
		people_alive.clear()
		_all_are_dead()
	else:
		var victim : String = people_alive.pick_random()
		people_alive.erase(victim)
		var killer : String = people_alive.pick_random()
		_kill(killer, victim)
		
		

func _all_are_dead():
	_write_to_log_with_delay(str("Sen var allt slut..."), 2)
	_write_to_log_with_delay(str("inget mer... inget mer..."), 4)
	_write_to_log_with_delay(str("......."), 6)
	_write_to_log_with_delay(str("...."), 8)
	_write_to_log_with_delay(str("."), 10)
	_write_to_log_with_delay(str(""), 12)
	_write_to_log_with_delay(str(""), 14)
	_write_to_log_with_delay(str(""), 16)

func _kill(killer : String, victim : String, in_revenge : bool = false):
	people_alive.erase(victim)
	_write_to_log(str(killer, " mördade ", victim, "."))
	if people_alive.size() == 1:
		_write_to_log_with_delay(str("...och nu var ", killer, " ensam kvar."), 1)
	elif people_alive.size() >= 2:
		var revenge : bool = randf() <= revenge_chance
		if !revenge:
			_write_to_log_with_delay("Men ingen brydde sig.", 1)
		else:
			people_alive.erase(killer)
			var revenger : String = people_alive.pick_random()
			_write_to_log_with_delay(str("Och då dödade ", revenger, " våldsamt ", killer, " som hämnd!!"), 1)

func _procreate_random():
	if people_alive.size() == 0:
		return
	
	if people_alive.size() == 1:
		var person : String = people_alive[0]
		_write_to_log(str(person, " vill ligga men det fanns ingen... de fick bli runk."))
	else:
		var p1 : String = people_alive.pick_random()
		var p2 : String = people_alive.pick_random()
		while p1 == p2:
			p2 = people_alive.pick_random()
		
		var new_person : String = _get_unused_name()
		people_alive.append(new_person)
		_write_to_log(str(p1, " låg med ", p2, " och nu finns ", new_person, "!"))
		

func _get_unused_name() -> String:
	if unused_names.size() > 0:
		var picked = unused_names.pick_random()
		unused_names.erase(picked)
		return picked
	return "Anonym Man" if randi_range(0,1) == 0 else "Anonym Kvinna"
