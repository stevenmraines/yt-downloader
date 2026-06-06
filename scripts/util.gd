class_name Util extends Object


static func get_windows_processes() -> Dictionary:
	var console_output = []
	OS.execute("tasklist", [], console_output, true)
	
	if console_output.size() > 0:
		var raw_output = console_output[0].split("\n")
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


static func get_unix_processes() -> Dictionary:
	var console_output = []
	OS.execute("ps", ["-e", "-o", "pid,comm"], console_output, true)
	
	if console_output.size() > 0:
		var raw_output = console_output[0].split("\n")
		var unix_processes = {}
		
		for process_str in raw_output:
			var regex = RegEx.new()
			regex.compile("\\S+")
			
			# FIXME Use regex.search like in the get_windows_processes function
			var pid = -1
			var process_name = ""
			for result in regex.search_all(process_str):
				if result.get_string().is_valid_int():
					pid = result.get_string().to_int()
				else:
					process_name = result.get_string()
			
			if pid > 0:
				unix_processes[pid] = process_name
		
		return unix_processes
	
	return {}
