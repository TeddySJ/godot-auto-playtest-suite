@tool
extends EditorPlugin

var editor_instance : AutoPlaySuite

func _enter_tree() -> void:
	editor_instance = preload("res://addons/auto_play_suite_editor/ui/auto_play_suite_editor.tscn").instantiate()
	get_editor_interface().get_editor_main_screen().add_child(editor_instance)
	
	editor_instance.current_context = AutoPlaySuite.CurrentContext.InPlugin_DontHaveScreen
	editor_instance.init_plugin()
	editor_instance._register_plugin_singleton()
	main_screen_changed.connect(editor_instance._on_editor_main_screen_changed)
	
	var editor_debugger_plugin : EditorDebuggerPlugin = preload("uid://dewiotl8wwqwn").new()
	add_debugger_plugin(editor_debugger_plugin)
	EngineDebugger.register_message_capture("aps", editor_debugger_plugin._capture)
	_make_visible(false)

func _exit_tree() -> void:
	if editor_instance:
		editor_instance.queue_free()

func _has_main_screen() -> bool:
	return true

func _make_visible(visible: bool) -> void:
	if editor_instance:
		editor_instance.visible = visible

func _get_plugin_name() -> String:
	return "AutoTest"

func _get_plugin_icon() -> Texture2D:
	return preload("res://addons/auto_play_suite_editor/icon.png")
