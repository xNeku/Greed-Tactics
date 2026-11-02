extends SceneTree
## Headless test runner. Usage (from the project folder):
##   godot --headless --import            (first time only, builds the class cache)
##   godot --headless --script res://tests/test_runner.gd
## Exit code is 0 when everything passes, 1 otherwise.
## Script errors raised while a test runs also make that test fail.

const TEST_DIRS: PackedStringArray = ["res://tests/unit"]


class ErrorCollector extends Logger:
	var errors: PackedStringArray = []
	var _mutex := Mutex.new()

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _script_backtrace: Array[ScriptBacktrace]) -> void:
		_mutex.lock()
		errors.append("%s (%s:%d)" % [rationale if not rationale.is_empty() else code, file, line])
		_mutex.unlock()

	func take() -> PackedStringArray:
		_mutex.lock()
		var result := errors.duplicate()
		errors.clear()
		_mutex.unlock()
		return result


func _initialize() -> void:
	var collector := ErrorCollector.new()
	OS.add_logger(collector)
	var passed := 0
	var failed := 0
	for dir in TEST_DIRS:
		for file in DirAccess.get_files_at(dir):
			if not (file.begins_with("test_") and file.ends_with(".gd")):
				continue
			var script: GDScript = load(dir.path_join(file))
			print("\n%s" % file)
			for method in script.get_script_method_list():
				var name: String = method.name
				if not name.begins_with("test_"):
					continue
				collector.take()
				var test: TestCase = script.new()
				test.before_each()
				test.call(name)
				var failures := test.get_failures()
				for error in collector.take():
					failures.append("script error: " + error)
				if failures.is_empty():
					passed += 1
					print("  ok    %s" % name)
				else:
					failed += 1
					print("  FAIL  %s" % name)
					for failure in failures:
						print("        - %s" % failure)
	OS.remove_logger(collector)
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
