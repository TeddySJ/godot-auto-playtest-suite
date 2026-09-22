extends SceneTree

var failures : int = 0


func _init() -> void:
	_run_regressions.call_deferred()


func _run_regressions() -> void:
	await _test_reorder_first_action_above_later_action()
	await _test_drop_mode_rearms_after_completed_drag()
	_test_new_test_updates_behavior_checkboxes()
	_test_changing_action_id_clears_generic_arguments()
	_test_filter_selects_first_match_when_current_action_does_not_match()
	_test_filter_keeps_current_action_when_it_matches()
	_test_filter_keeps_current_action_when_nothing_matches()
	_test_extra_vars_are_editable()
	_test_extra_vars_preserve_empty_positions()
	_test_selecting_an_action_does_not_modify_it()
	_test_switching_actions_commits_pending_float_as_an_edit()
	await _test_pending_float_is_attributed_to_its_owning_test()
	_test_action_description_is_displayed()
	await _test_long_action_description_stays_above_fields()
	_test_series_reorder_keeps_backing_arrays_aligned()
	_test_unchanged_test_path_does_not_dirty_series()
	_test_series_loaded_test_starts_clean()
	_test_no_op_action_list_sync_does_not_dirty_test()
	await _test_unsaved_test_removal_requires_confirmation()
	await _test_empty_list_offers_paste_when_clipboard_has_actions()
	_test_copy_captures_an_action_snapshot()
	AutoPlaySuiteActionLibrary.clear_library()
	await process_frame

	if failures == 0:
		print("UI_AUTHORING_REGRESSION_SUCCESS")
	quit(failures)


func _test_reorder_first_action_above_later_action() -> void:
	var tree := AutoPlaySuiteActionList.new()
	root.add_child(tree)
	tree.size = Vector2(400, 400)
	for action_id : StringName in [&"A", &"B", &"C"]:
		tree.add_and_bind_item(action_id, AutoPlaySuiteActionResource.Create(action_id))

	var items := tree.root.get_children()
	items[0].select(0)
	await process_frame
	var target_rect := tree.get_item_area_rect(items[2], 0)
	var above_target := target_rect.position + Vector2(4.0, 1.0)
	tree._drop_data(above_target, {"from": items[0]})

	var actual_order : Array = tree.get_all_items().map(
		func(action : AutoPlaySuiteActionResource) -> StringName: return action.action_id
	)
	_expect(actual_order == [&"B", &"A", &"C"], "The first action should move above a later target.")
	tree.queue_free()


func _test_drop_mode_rearms_after_completed_drag() -> void:
	var tree := AutoPlaySuiteActionList.new()
	root.add_child(tree)
	tree.size = Vector2(400, 400)
	for action_id : StringName in [&"A", &"B", &"C"]:
		tree.add_and_bind_item(action_id, AutoPlaySuiteActionResource.Create(action_id))
	await process_frame

	var first_item := tree.root.get_child(0)
	first_item.select(0)
	var first_target := tree.root.get_child(2)
	var first_target_rect := tree.get_item_area_rect(first_target, 0)
	var above_first_target := first_target_rect.position + Vector2(4.0, 1.0)
	var first_drag_data := {"from": first_item}
	_expect(tree._can_drop_data(above_first_target, first_drag_data), "The first reorder should be accepted.")
	tree._drop_data(above_first_target, first_drag_data)
	await process_frame

	tree.notification(Node.NOTIFICATION_DRAG_END)
	_expect(
		tree.drop_mode_flags == Tree.DROP_MODE_DISABLED,
		"Godot should disable the tree's drop mode after a completed drag."
	)

	tree.deselect_all()
	var second_item := tree.root.get_child(0)
	second_item.select(0)
	var second_target := tree.root.get_child(2)
	var second_target_rect := tree.get_item_area_rect(second_target, 0)
	var below_second_target := second_target_rect.position + Vector2(4.0, second_target_rect.size.y - 1.0)
	var second_drag_data := {"from": second_item}
	var can_drop_again := tree._can_drop_data(below_second_target, second_drag_data)
	_expect(can_drop_again, "A second reorder should be accepted after drag end.")
	_expect(
		tree.drop_mode_flags == Tree.DROP_MODE_INBETWEEN,
		"Accepting another drag should re-enable the in-between drop mode."
	)
	tree._drop_data(below_second_target, second_drag_data)
	var actual_order : Array = tree.get_all_items().map(
		func(action : AutoPlaySuiteActionResource) -> StringName: return action.action_id
	)
	_expect(actual_order == [&"A", &"C", &"B"], "The second reorder should update the action order.")
	tree.queue_free()


func _test_copy_captures_an_action_snapshot() -> void:
	var tree := AutoPlaySuiteActionList.new()
	root.add_child(tree)
	var source : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"A", 1.0)
	tree.add_and_bind_item("A", source)
	var item := tree.root.get_child(0)
	item.select(0)
	tree._on_cell_selected()
	tree._copy_entries()
	source.float_var = 99.0
	tree._paste_entries()
	var pasted := tree.get_all_items()[1] as AutoPlaySuiteActionResource
	_expect(pasted.float_var == 1.0, "Copy should capture action values at copy time.")
	tree.queue_free()


func _test_new_test_updates_behavior_checkboxes() -> void:
	var view := AutoPlaySuiteUiCurrentTestView.new()
	root.add_child(view)
	view.new_test()
	_expect(
		view.premature_end_is_error.button_pressed == view.current_test.premature_end_is_error,
		"A new test's unexpected-end checkbox should match its resource value."
	)
	_expect(
		view.stop_series_on_error.button_pressed == view.current_test.stop_series_on_error,
		"A new test's stop-series checkbox should match its resource value."
	)
	view.queue_free()


func _test_empty_list_offers_paste_when_clipboard_has_actions() -> void:
	var tree := AutoPlaySuiteActionList.new()
	root.add_child(tree)
	tree.add_and_bind_item("A", AutoPlaySuiteActionResource.Create(&"A"))
	var item := tree.root.get_child(0)
	item.select(0)
	tree._on_cell_selected()
	tree._cut_entries()
	tree._create_right_click_thing()

	var popup : PopupMenu = null
	for child in tree.get_children():
		if child is PopupMenu:
			popup = child
	_expect(popup != null, "An empty action list should still create its context menu.")
	if popup != null:
		_expect(
			popup.get_item_index(AutoPlaySuiteActionList.PopupChoice.Paste) != -1,
			"An empty action list should offer Paste when its clipboard contains actions."
		)
		popup.hide()
		await process_frame
		_expect(!is_instance_valid(popup), "A dismissed action-list popup should be freed.")
		_expect(AutoPlaySuite.shared_popup == null, "Dismissing a popup should clear the shared popup reference.")
	tree.queue_free()


func _test_changing_action_id_clears_generic_arguments() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Old")
	view._add_drop_down_item(&"New")
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Old", 42.0, "stale", ["stale"])
	view._set_action(action)
	var new_index := view.drop_down.get_item_index(view.backing_dictionary[&"New"])
	view._action_id_changed(new_index)
	_expect(action.float_var == 0.0, "Changing action ID should reset the float argument.")
	_expect(action.string_var.is_empty(), "Changing action ID should reset the string argument in the resource.")
	_expect(action.extra_vars.is_empty(), "Changing action ID should reset the extra string arguments.")
	view.queue_free()


func _test_filter_selects_first_match_when_current_action_does_not_match() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._fill_drop_down([&"Wait", &"LMB Press", &"LMB Release"])
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Wait")
	view._set_action(action)
	view._filter_drop_down("lmb")
	_expect(view.drop_down.item_count == 2, "Filtering should only display matching actions when matches exist.")
	_expect(action.action_id == &"LMB Press", "Filtering should change a nonmatching action to the first match.")
	_expect(view.drop_down.get_selected_id() == view.backing_dictionary[&"LMB Press"], "The first match should be selected in the dropdown.")
	view.queue_free()


func _test_filter_keeps_current_action_when_it_matches() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._fill_drop_down([&"Wait", &"LMB Press", &"LMB Release"])
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"LMB Release")
	view._set_action(action)
	view._filter_drop_down("lmb")
	_expect(action.action_id == &"LMB Release", "Filtering should keep the current action when it matches.")
	_expect(view.drop_down.get_selected_id() == view.backing_dictionary[&"LMB Release"], "A matching current action should remain selected.")
	view.queue_free()


func _test_filter_keeps_current_action_when_nothing_matches() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._fill_drop_down([&"Wait", &"LMB Press", &"LMB Release"])
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Wait")
	view._set_action(action)
	view._filter_drop_down("no matches")
	_expect(action.action_id == &"Wait", "Filtering should keep the current action when nothing matches.")
	_expect(view.drop_down.get_selected_id() == view.backing_dictionary[&"Wait"], "The current action should remain selected when nothing matches.")
	view.queue_free()


func _test_extra_vars_are_editable() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Action")
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(
		&"Action",
		0.0,
		"",
		["one", "two"]
	)
	view._set_action(action)
	_expect(view.extra_vars_text_edit.text == "one\ntwo", "The inspector should display every extra string argument.")
	view.extra_vars_text_edit.text = "three\nfour"
	view._extra_vars_changed()
	_expect(action.extra_vars == ["three", "four"], "Editing extra arguments should update the action resource.")
	view.queue_free()


func _test_extra_vars_preserve_empty_positions() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Action")
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Action")
	view._set_action(action)
	view.extra_vars_text_edit.text = "first\n\nthird\n"
	view._extra_vars_changed()
	_expect(
		action.extra_vars == ["first", "", "third", ""],
		"Extra arguments should preserve empty positional and trailing values."
	)
	view.extra_vars_text_edit.text = ""
	view._extra_vars_changed()
	_expect(action.extra_vars.is_empty(), "An empty extra-arguments editor should produce an empty array.")
	view.queue_free()


func _test_selecting_an_action_does_not_modify_it() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Action")
	var change_count := [0]
	view.signal_on_action_changed.connect(func(_action : AutoPlaySuiteActionResource) -> void: change_count[0] += 1)
	var action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(
		&"Action",
		12.0,
		"value",
		["extra"],
		30.0
	)
	view._set_action(action)
	_expect(change_count[0] == 0, "Selecting an action should not emit an edit notification.")
	view.queue_free()


func _test_switching_actions_commits_pending_float_as_an_edit() -> void:
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"First")
	view._add_drop_down_item(&"Second")
	var first : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"First", 1.0)
	var second : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Second", 2.0)
	view._set_action(first)
	var change_count := [0]
	view.signal_on_action_changed.connect(func(_action : AutoPlaySuiteActionResource) -> void: change_count[0] += 1)
	view.float_var_spinbox.get_line_edit().text = "7"
	view._set_action(second)
	_expect(first.float_var == 7.0, "Switching actions should commit the pending float edit.")
	_expect(change_count[0] == 1, "Committing a pending float edit should emit one modification signal.")
	view.queue_free()


func _test_pending_float_is_attributed_to_its_owning_test() -> void:
	var series_view := AutoPlaySuiteUiTestSeriesView.new()
	var current_view := AutoPlaySuiteUiCurrentTestView.new()
	var action_view := AutoPlaySuiteUiActionView.new()
	root.add_child(series_view)
	root.add_child(current_view)
	root.add_child(action_view)
	action_view._add_drop_down_item(&"Action")

	var first_action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Action", 1.0)
	var second_action : AutoPlaySuiteActionResource = AutoPlaySuiteActionResource.Create(&"Action", 2.0)
	var first_test := AutoPlaySuiteTestResource.new()
	first_test.test_name = "First"
	first_test.actions.append(first_action)
	var second_test := AutoPlaySuiteTestResource.new()
	second_test.test_name = "Second"
	second_test.actions.append(second_action)
	series_view.add_test(first_test, false)
	series_view.add_test(second_test, false)
	series_view.series_has_unsaved_changes = false
	var editor := AutoPlaySuite.new()
	editor.test_series_view = series_view
	editor.current_test_view = current_view
	editor.action_view = action_view
	current_view.signal_on_current_test_modified.connect(series_view.mark_test_dirty)
	current_view.signal_on_before_test_change.connect(action_view.commit_pending_edits)
	series_view.signal_on_before_series_operation.connect(action_view.commit_pending_edits)
	action_view.signal_on_action_changed.connect(editor._on_action_changed)

	current_view.set_current_test(first_test)
	action_view._set_action(first_action)
	action_view.float_var_spinbox.get_line_edit().text = "7"
	current_view.set_current_test(second_test)
	action_view._set_action(second_action)

	_expect(first_action.float_var == 7.0, "Switching tests should commit the first test's pending float edit.")
	_expect(series_view.dirty_tests[first_test], "The test that owns a pending float edit should become dirty.")
	_expect(!series_view.dirty_tests[second_test], "The newly selected test should remain clean.")

	action_view.float_var_spinbox.get_line_edit().text = "9"
	var original_series := series_view.current_test_series
	series_view._new_series_button_pressed()
	_expect(second_action.float_var == 9.0, "A destructive series action should first commit the current float edit.")
	_expect(series_view.dirty_tests[second_test], "The current test should be dirty before a destructive series check.")
	_expect(series_view.current_test_series == original_series, "A pending edit should trigger confirmation before replacing the series.")
	_expect(is_instance_valid(series_view.confirmation_dialog), "Replacing a series with a pending edit should request confirmation.")
	series_view._clear_confirmation_dialog()
	await process_frame
	series_view.queue_free()
	current_view.queue_free()
	action_view.queue_free()
	editor.free()


func _test_action_description_is_displayed() -> void:
	AutoPlaySuiteActionLibrary.clear_library()
	var definition : AutoPlaySuiteInstructionDefinition = AutoPlaySuiteInstructionDefinition.Create(
		func(_action : AutoPlaySuiteActionResource) -> void: pass,
		"Regression action help"
	)
	AutoPlaySuiteActionLibrary.add_actions_to_library({&"Described Action": definition})
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Described Action")
	view._set_action(AutoPlaySuiteActionResource.Create(&"Described Action"))
	_expect(view.description_label.text == "Regression action help", "The inspector should display action help text.")
	view.queue_free()


func _test_long_action_description_stays_above_fields() -> void:
	AutoPlaySuiteActionLibrary.clear_library()
	var long_description := "This deliberately long action description should wrap over several lines without overlapping the editable fields below it. ".repeat(4)
	var definition : AutoPlaySuiteInstructionDefinition = AutoPlaySuiteInstructionDefinition.Create(
		func(_action : AutoPlaySuiteActionResource) -> void: pass,
		long_description
	)
	AutoPlaySuiteActionLibrary.add_actions_to_library({&"Long Description": definition})
	var view := AutoPlaySuiteUiActionView.new()
	root.add_child(view)
	view._add_drop_down_item(&"Long Description")
	view._set_action(AutoPlaySuiteActionResource.Create(&"Long Description"))
	await process_frame
	_expect(
		view.description_label.position.y + view.description_label.size.y <= view.float_var_spinbox.position.y,
		"A long action description should not overlap the Float Var field."
	)
	view.queue_free()


func _test_series_reorder_keeps_backing_arrays_aligned() -> void:
	var view := AutoPlaySuiteUiTestSeriesView.new()
	root.add_child(view)
	var first := AutoPlaySuiteTestResource.new()
	first.test_name = "First"
	var second := AutoPlaySuiteTestResource.new()
	second.test_name = "Second"
	var third := AutoPlaySuiteTestResource.new()
	third.test_name = "Third"
	view.add_test(first)
	view.add_test(second)
	view.add_test(third)
	view.current_test_series.paths_to_tests = ["first", "second", "third"]
	view.current_test_series.number_of_runs_per_test = [1, 2, 3]
	view._move_selected_test(-1)

	var ordered_tests := view._get_all_tests_in_order()
	_expect(ordered_tests[0] == first, "Moving a series test should retain the preceding test.")
	_expect(ordered_tests[1] == third, "The selected test should move one position left.")
	_expect(view.current_test_series.paths_to_tests == ["first", "third", "second"], "Series paths should follow test reordering.")
	_expect(view.current_test_series.number_of_runs_per_test == [1, 3, 2], "Run counts should follow test reordering.")
	view.queue_free()


func _test_unchanged_test_path_does_not_dirty_series() -> void:
	var view := AutoPlaySuiteUiTestSeriesView.new()
	root.add_child(view)
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = "Saved"
	view.add_test(test)
	view.current_test_series.paths_to_tests[0] = "uid://same-path"
	view.series_has_unsaved_changes = false
	view._update_path_to_current_test("uid://same-path")
	_expect(!view.series_has_unsaved_changes, "Saving to the existing test path should not dirty the series.")
	view._update_path_to_current_test("uid://different-path")
	_expect(view.series_has_unsaved_changes, "Changing a test path should dirty the series.")
	view.queue_free()


func _test_series_loaded_test_starts_clean() -> void:
	var view := AutoPlaySuiteUiTestSeriesView.new()
	root.add_child(view)
	var loaded_test := AutoPlaySuiteTestResource.new()
	loaded_test.test_name = "Loaded path resource"
	view.add_test(loaded_test, false)
	view.series_has_unsaved_changes = false
	_expect(!view.dirty_tests[loaded_test], "A test loaded from a series path should start clean.")
	_expect(!view.has_unsaved_work(), "A freshly loaded path-based series should not prompt for unsaved work.")
	view.queue_free()


func _test_no_op_action_list_sync_does_not_dirty_test() -> void:
	var view := AutoPlaySuiteUiCurrentTestView.new()
	root.add_child(view)
	var test := AutoPlaySuiteTestResource.new()
	test.test_name = "Saved"
	test.actions.append(AutoPlaySuiteActionResource.Create(&"Action"))
	view.set_current_test(test)
	var modification_count := [0]
	view.signal_on_current_test_modified.connect(
		func(_test : AutoPlaySuiteTestResource) -> void: modification_count[0] += 1
	)
	view._sync_current_test_to_list()
	_expect(modification_count[0] == 0, "Synchronizing an unchanged action list should not dirty the test.")
	view.queue_free()


func _test_unsaved_test_removal_requires_confirmation() -> void:
	var view := AutoPlaySuiteUiTestSeriesView.new()
	root.add_child(view)
	var unsaved_test := AutoPlaySuiteTestResource.new()
	unsaved_test.test_name = "Unsaved"
	view.add_test(unsaved_test)
	var original_series := view.current_test_series
	view._new_series_button_pressed()
	_expect(view.current_test_series == original_series, "Replacing a dirty series should wait for confirmation.")
	_expect(is_instance_valid(view.confirmation_dialog), "Replacing a dirty series should show a confirmation dialog.")
	view._clear_confirmation_dialog()
	await process_frame
	view._remove_test_button_pressed()
	_expect(view.test_button_list.size() == 1, "Removing an unsaved test should wait for confirmation.")
	_expect(is_instance_valid(view.confirmation_dialog), "Removing an unsaved test should show a confirmation dialog.")
	view._clear_confirmation_dialog()
	await process_frame
	view._remove_test_button_pressed(true)
	_expect(view.test_button_list.is_empty(), "Confirmed removal should remove the unsaved test.")
	view.queue_free()


func _expect(condition : bool, message : String) -> void:
	if condition:
		return
	failures += 1
	push_error(message)
