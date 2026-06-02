class_name ConsoleSignalBus extends Node

signal line_added(line : String)
signal warning_added(warning : String)
signal error_added(err : String)


func add_line(line : String) -> void:
	line_added.emit(line)


func add_warning(warning : String) -> void:
	warning_added.emit(warning)


func add_error(err : String) -> void:
	error_added.emit(err)
