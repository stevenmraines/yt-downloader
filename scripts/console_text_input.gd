extends RichTextLabel


func _on_console_signal_bus_line_added(line: String) -> void:
	_write_to_console(line, Color.GRAY)


func _on_console_signal_bus_error_added(err: String) -> void:
	_write_to_console(err, Color.RED)


func _on_console_signal_bus_warning_added(warning: String) -> void:
	_write_to_console(warning, Color.YELLOW)


func _write_to_console(message : String, text_color : Color) -> void:
	push_color(text_color)
	add_text(message + "\n")
	pop()
	scroll_to_line(get_line_count() - 1)
