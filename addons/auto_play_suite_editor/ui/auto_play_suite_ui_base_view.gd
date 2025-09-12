extends Control
class_name AutoPlaySuiteUiView

func _enter_tree() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	pass
