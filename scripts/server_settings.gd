extends FoldableContainer

@onready var name_input := %NameInput
@onready var ip_input := %IPInput
@onready var user_input := %UserInput
@onready var ssh_key_path_input := %SSHKeyPathInput
@onready var ssh_key_path_file_dialog := %SSHKeyPathFileDialog
@onready var is_default_input := %IsDefaultInput

var server : Dictionary:
	set(value):
		server = value
		title = server.name
		name_input.text = server.name
		ip_input.text = server.ip
		user_input.text = server.user
		ssh_key_path_input.text = server.ssh_key_path
		is_default_input.button_pressed = server.is_default


func _on_name_input_text_changed(new_text: String) -> void:
	title = new_text


func get_data() -> Dictionary:
	return {
		"name": name_input.text,
		"ip": ip_input.text,
		"user": user_input.text,
		"ssh_key_path": ssh_key_path_input.text,
		"is_default": is_default_input.button_pressed,
	}
