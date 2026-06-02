extends RichTextLabel


func _on_console_signal_bus_line_added(line: String) -> void:
	push_color(Color.GRAY)
	add_text(line + "\n")
	pop()


func _on_console_signal_bus_error_added(err: String) -> void:
	push_color(Color.RED)
	add_text(err + "\n")
	pop()


func _on_console_signal_bus_warning_added(warning: String) -> void:
	push_color(Color.YELLOW)
	add_text(warning + "\n")
	pop()
