# Auto Play Suite contributor guide

## Purpose

Auto Play Suite is a Godot 4.7 editor plugin and runtime harness for scripted smoke/play tests. Its job is to exercise a game's essential flow automatically and evaluate the game periodically so release-blocking regressions are caught before a public build. It is a safety net for core functionality, not a replacement for normal QA, focused unit/integration tests, or exploratory testing.

The addon is deliberately game-agnostic. It supplies sequencing, authoring, logging, evaluation, and editor/runtime communication; each adopting game is expected to register the actions and state checks that make sense for that game.

The reusable addon is in `addons/auto_play_suite_editor/`. Files at the repository root (`game.gd`, `custom_instructions.gd`, the custom logger/evaluator scripts, and the two root scenes) form a demo project. Resources in `tests/` are example playtest definitions, not a conventional unit-test suite.

## Repository map

- `auto_play_suite_plugin.gd`: installs the `AutoTest` editor main screen and debugger message capture.
- `ui/`: creates and coordinates the test/series editor, ordered action lists, action inspector, and log viewer.
- `resource_definitions/`: serializable action, test, and test-series resources.
- `instructions/`: action definition type, built-in actions, and discovery of game-specific instruction sets.
- `helpers/auto_play_suite_test_runner.gd`: runtime action queue and test lifecycle.
- `helpers/auto_play_suite_hook_node.gd`: bridge placed in the game's main scene to start a requested test.
- `logging/` and `evaluation/`: extension bases and debugger-message reporting.
- `tests/*.test.tres`: ordered actions for one test; `*.testseries.tres`: ordered references to test resources.

## Program flow

1. Enabling the plugin instantiates `auto_play_suite_editor.tscn` as the `AutoTest` main screen. It loads all instruction sets and registers the `aps` debugger channel.
2. `AutoPlaySuiteInstructionLoader` scans Godot's global class list for class names containing `AutoPlaySuiteInstructionSet`. Each discovered object must implement `hook_into_suite()` and register its definitions with `AutoPlaySuiteActionLibrary`.
3. The editor UI creates or loads `AutoPlaySuiteTestResource` objects. A test owns an ordered main-action list, an optional post-action list, and the `premature_end_is_error` flag. A series stores ordered UID/path strings for saved tests.
4. Starting a test saves it, sets `DoAutoTesting=true` and `AutoTestPath`, and launches the project's main scene. Therefore an adopting project's startup scene must contain an `AutoPlaySuiteHookNode` (or equivalent code that invokes the runner).
5. The hook reads the environment and starts `AutoPlaySuiteTestRunner`. The runner duplicates the resource and executes actions in order. `on_enter` is called once when an action is first entered; `on_process(delta, action)` is called every frame until the action sets `action.finished = true`. The runner uses `PROCESS_MODE_ALWAYS`, so actions continue while the scene tree is paused.
6. `interrupt_with_this_action()` can put a high-priority action in front of the current action. After the interruption, the previous action resumes without calling its `on_enter` callback again.
7. Loggers and evaluators send structured data back over `EngineDebugger` messages in the `aps:logging` channel. Evaluators report failed checks through `AutoPlaySuiteEvaluator.log_failed_evaluation()`.
8. A normal scripted exit goes through `AutoPlaySuiteTestRunner.QuitGame()`. It notifies the editor, starts any post actions, and quits the game. The editor waits for the game process to stop, then marks the test failed if a failed evaluation was logged or if the game exited unexpectedly while `premature_end_is_error` is enabled.
9. A series runs its tests sequentially and displays the accumulated logs. At present, each test runs once; `number_of_runs_per_test` exists on the series resource but is not consumed by the runner.

## Adding game-specific behavior

- Define a `RefCounted` global class whose name contains `AutoPlaySuiteInstructionSet`.
- Store actions in a `Dictionary[StringName, AutoPlaySuiteInstructionDefinition]` and register it from `hook_into_suite()`.
- Use `AutoPlaySuiteInstructionDefinition.Create(on_enter, description, on_process)`.
- `on_enter` receives an `AutoPlaySuiteActionResource`. A per-frame callback receives `(delta: float, action_resource: AutoPlaySuiteActionResource)`.
- Every finite action must eventually set `action_resource.finished = true`; otherwise the queue intentionally remains on that action.
- Use `float_var`, `string_var`, and `extra_vars` as the generic serialized arguments. Keep action IDs stable because `.tres` files persist them by string.
- Extend `AutoPlaySuiteLogger` for telemetry and `AutoPlaySuiteEvaluator` for assertions about game state. Register these as global classes so the runtime factories can discover them. Use the root demo scripts as examples, not as addon dependencies.
- Route intended test shutdown through `QuitGame()` rather than quitting the tree directly when correct-exit detection matters.


## Coding style

- Follow the existing Godot 4 GDScript style: tabs for indentation, `snake_case` for functions and variables, `PascalCase` for `class_name` types, and descriptive `signal_on_...` signal names.
- Prefer explicit types for public state, parameters, return values, typed arrays, and dictionaries. Match the repository's declaration spacing (`var name : Type`, `func name(arg : Type) -> Type`). Local inference with `:=` is appropriate when the type is obvious.
- Use `StringName` values (`&"..."`) for stable action IDs, method names, and message tokens where the surrounding API already does so.
- Put editor-only integration in `@tool` scripts. Guard APIs that only exist in the editor with `Engine.is_editor_hint()` or the existing context enum.
- Keep resource data separate from runtime state. Duplicate test/action resources before execution when mutation is expected; the runner relies on mutable `entered` and `finished` flags.
- Prefer signals for UI and game-event coordination, deferred calls when adding runtime nodes during startup, and `await`/timers for asynchronous action completion.
- Preserve existing public names such as `Singleton`, `Create`, `LoadAllInstructions`, and `QuitGame` unless deliberately making a coordinated API migration. New APIs should use the normal naming rules above.
- Keep generic addon code free of references to demo/game classes. Game-specific instructions, loggers, and evaluators belong in the adopting project.
- Comments should explain integration constraints, non-obvious state transitions, or intentional limitations. Remove temporary debug prints and stale commented-out experiments when touching nearby code.

## Validation

- If, and only if, you have made script changes, run `godot_console --headless --quit project.godot` to check for script compile errors. The first run may fail because of editor-data, configuration, cache, certificate, or other environment-access issues. When that happens, run the command again and distinguish environment warnings from actual parse, type, or runtime script errors.
- A compile-only launch is not sufficient for changes involving state transitions, sequencing, callbacks, queues, resource mutation, or asynchronous behavior. For those changes, create a small focused headless validation script inside the project, run it with `godot_console --headless --path . --script res://path/to/validation_script.gd`, and exercise the real production classes rather than a reimplementation of their logic.
- Keep the validation scenario minimal. Register only the dependencies it needs, construct the smallest useful resources or nodes, drive the relevant lifecycle directly, and assert externally observable state after each important transition. Include normal behavior plus applicable boundary cases such as repeated entry, resume/re-entry, nesting, stale input state, completion, and shutdown.
- Make the validation script print an unambiguous success marker and quit with a nonzero status when an assertion fails. Inspect the complete output as well as the exit code: deferred work can emit a script error after success was printed or after a quit was requested.
- Keep a focused validation as a permanent regression test when it fits the repository's test organization. Otherwise, remove the temporary script after it passes and report the exact scenario that was exercised.
- Finish by rerunning the compile check and `git diff --check`, then inspect the final diff and working-tree status for accidental files or unrelated edits.
