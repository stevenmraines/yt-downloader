extends VBoxContainer

@onready var name_input := %NameInput
@onready var ip_input := %IPInput
@onready var user_input := %UserInput
@onready var ssh_key_path_input := %SSHKeyPathInput
@onready var ssh_key_path_file_dialog := %SSHKeyPathFileDialog
@onready var is_default_input := %IsDefaultInput

var server : Dictionary:
	set(value):
		server = value
		name_input.text = server.name
		ip_input.text = server.ip
		is_default_input.button_pressed = server.default

var credentials : Dictionary:
	set(value):
		credentials = value
		user_input.text = credentials.user
		ssh_key_path_input.text = credentials.ssh_key_path
