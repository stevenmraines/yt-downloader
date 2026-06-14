class_name Util extends Object


static func _get_windows_processes() -> Dictionary:
	var console_output = []
	OS.execute("tasklist", [], console_output, true)
	
	if console_output.size() > 0:
		var raw_output = console_output[0].split("\n")
		# These first 3 lines are all just headers
		raw_output.remove_at(0)
		raw_output.remove_at(0)
		raw_output.remove_at(0)
		var windows_processes = {}
		
		for process_str in raw_output:
			var regex = RegEx.new()
			regex.compile("^(?<name>.+?)\\s+(?<pid>\\d+)\\s+")
			var result = regex.search(process_str)
			
			if result:
				var pid = int(result.get_string("pid"))
				var process_name = result.get_string("name").strip_edges()
				windows_processes[pid] = process_name
		
		return windows_processes
	
	return {}


static func _get_unix_processes() -> Dictionary:
	var console_output = []
	OS.execute("ps", ["-e", "-o", "pid,comm"], console_output, true)
	
	if console_output.size() > 0:
		var raw_output = console_output[0].split("\n")
		# First element is just a header, get rid of it
		raw_output.remove_at(0)
		var unix_processes = {}
		
		for process_str in raw_output:
			var regex = RegEx.new()
			regex.compile("^(?<pid>\\d+)\\s+(?<name>\\S+)")
			var result = regex.search(process_str)
			
			if result:
				var pid = int(result.get_string("pid"))
				var process_name = result.get_string("name").strip_edges()
				unix_processes[pid] = process_name
		
		return unix_processes
	
	return {}


static func get_processes() -> Dictionary:
	if OS.get_name() == "Windows":
		return _get_windows_processes()
	else:
		return _get_unix_processes()


static func scp(file : String, destination, ip : String, user : String, ssh_key_path : String) -> int:
	return OS.create_process("scp", [
		file, "-i", ssh_key_path, "%s@%s:%s" % [user, ip, destination]
	], true)


static func get_archive_file_path(playlist : Dictionary) -> String:
	return OS.get_user_data_dir() + "/archived/" + playlist.channel \
		+ "/" + playlist.download_archive_file_name
