class_name TestCase
extends RefCounted
## Base class for headless tests. Every method starting with "test_" is run on
## a fresh instance by tests/test_runner.gd. Keep tests free of scenes/nodes.

var _failures: PackedStringArray = []


## Called before each test method on its fresh instance.
func before_each() -> void:
	pass


func get_failures() -> PackedStringArray:
	return _failures


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		_fail("expected true. " + message)


func assert_false(condition: bool, message: String = "") -> void:
	if condition:
		_fail("expected false. " + message)


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if typeof(actual) != typeof(expected) or actual != expected:
		_fail("expected <%s> but got <%s>. %s" % [expected, actual, message])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		_fail("did not expect <%s>. %s" % [unexpected, message])


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		_fail("expected null but got <%s>. %s" % [value, message])


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		_fail("expected a value but got null. " + message)


func assert_has(collection: Variant, item: Variant, message: String = "") -> void:
	if not collection.has(item):
		_fail("expected collection to contain <%s>. %s" % [item, message])


func assert_not_has(collection: Variant, item: Variant, message: String = "") -> void:
	if collection.has(item):
		_fail("expected collection NOT to contain <%s>. %s" % [item, message])


func _fail(message: String) -> void:
	_failures.append(message)
