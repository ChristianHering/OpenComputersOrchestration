--- https://pastebin.com/f6j6AGLf
shell.run("./json-api")

local turtleID --- Computer's label

--- Variable defaults
local orchestratorHost = "http://65.31.180.195:8001"
local sleepInterval = 10

--- Tasks are tables (structs) with 2+ options. (With the exception of "none" responses)
--- Option 1 is a package and the command to run seperated with a slash
--- Option 2 is weather the orchestration server would like us to POST it the result
--- Any further options are passed to the called function as arguments
--- If calling functions from external scripts, Option 3 is the version string
local taskQueue = {}

local args = { ... }

--- Global help message
if (args[1] == "help" or args[1] == "h") then
	print("---This is the main orchestration script for turtle operation.")
	print("---It can download and execute sub scripts, arbitrary tasks, etc.")
	print("")
	print("CLI Options:")
	print("-Orchestration server host address. Must include protocol, ip, and port.")
	print("")
	print("-Global sleep interval value. Defines the default sleep length in seconds.")
end

if args[1] ~= nil then
	orchestratorHost = args[1]
end
if args[2] ~= nil then
	sleepInterval = args[2]
end

--- Sets turtleID and validates orchestration server URL
function init()
	turtleID = string.match(shell.run("label get"), [[var%s+"([%d,]+)]])
	print("Got turtle ID: ", turtleID)

	local success, message = http.checkURL(orchestratorHost)

	if not success then
		error( "Invalid URL: " .. message )
	else
		print("Got server host: ", orchestratorHost)
	end
end

--- https://stackoverflow.com/a/7615129
function srtSplit (inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	
	local t={}
	
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end

	return t
end

--- https://stackoverflow.com/a/24823383
function table.slice(tbl, first, last, step)
	local sliced = {}

	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced+1] = tbl[i]
	end

	return sliced
end

--- Updates the orchestration server with our status
function updateStatus(status)
	local reqHandle = http.post(orchestratorHost + "/" + turtleID + "/updateStatus", json.encode(status))
	if reqHandle == nil then
		print("Error sending our status to.")
		return -1
	end

	reqHandle.close()

	return 0
end

--- Gets the nest task(s) (if any) from the orchestration server
function getTask()
	local reqHandle = http.get(orchestratorHost + "/" + turtleID + "/getTask")
	if reqHandle == nil then
		print("Error getting task from orchestration server.")
		return -1
	end

	reqHandle.close()

	return json.decode(reqHandle.readAll())
end

--- Loops through each task, and adds it to the task queue
function populateTaskQueue(tasks)
	if tasks[1][1] ~= "none" then
		local i = 0

		while i < tasks.length do
			table.insert(taskQueue, tasks[i+1])
		end
	end
end

--- Constantly pings the orchestration server for new tasks, then adds them to the queue
function taskHandler()
	while true do
		local tasks = getTask()
		if tasks ~= -1 then
			populateTaskQueue(tasks)
		end

		os.sleep(sleepInterval)
	end
end

--- Checks a local script's version/downloads the latest script
--- Versioning is based off a version string (first line of file)
function downloadScript(scriptName, versionString)
	print("Downloading script: ", scriptName)

	local script = io.open(scriptName, "r")

	if script ~= nil and script:read() == versionString then
		print("Script already latest version")

		io.close(script)

		return 0
	end

	script:close()

	local resp = http.get(orchestratorHost + "/scripts/" + scriptName + ".lua ")
	if resp == nil then
		print("Error retrieving script from orchestration server.")
		return -1
	end

	local script = io.open(scriptName, "w")

	script:write(resp.readAll())

	script.close()

	resp.close()

	return 0
end

--- Pseudo-switch statement for core functions
local switch = {
	["core/getTask"] = function()
		local tasks = getTask()
		if tasks ~= -1 then
			populateTaskQueue(tasks)
		end

		if taskQueue[2] then --- Nobody should really call this...
			updateStatus(taskQueue[1], tasks)			
		end
	end,

	["core/downloadScript"] = function()
		local resp = downloadScript(taskQueue[3], taskQueue[4])

		if taskQueue[2] then
			updateStatus(taskQueue[1], resp)
		end
	end,

	["core/executeScript"] = function()
		local resp = shell.run("./", taskQueue[3])

		if taskQueue[2] then
			updateStatus(taskQueue[1], resp)
		end
	end,

	["core/deleteScript"] = function()
		local resp = shell.run("./delete ", taskQueue[3])

		if taskQueue[2] then
			updateStatus(taskQueue[1], resp)
		end
	end
}

--- Sequentially executes tasks in the task queue
function executionHandler()
	while true do
		if taskQueue.length > 0 then
			local taskFunction = switch[taskQueue[1]]
			if taskFunction then
				taskFunction()
			else
				local cmdTable = strSplit(taskQueue[1], " ")
		
				local resp = downloadScript(cmdTable[1], taskQueue[3])
				if resp == -1 and taskQueue[2] == true then
					updateStatus(taskQueue[1], resp)
				end

				local argTable = table.slice(cmdTable, 2, cmdTable.length)

				local resp = shell.run("./", cmdTable[1], argTable)
				if resp == -1 and taskQueue[2] == true then
					updateStatus(taskQueue[1], resp)
				end
			end
		else
			local tasks = getTask()
			if tasks ~= -1 then
				populateTaskQueue(tasks)
			end
		end

		table.remove(taskQueue[1])
	end
end

--- Main
function threadMain()
	init()

	os.startThread(taskHandler)
	os.startThread(executionHandler)

end

--- https://pastebin.com/KYtYxqHh
shell.run("./thread-api")