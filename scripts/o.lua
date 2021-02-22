local internet = require("internet") --- Builtin - https://ocdoc.cil.li/api:internet
local json = require("json-api") --- https://pastebin.com/f6j6AGLf

local turtleID --- Computer's label

--- Variable defaults
OrchestratorHost = "http://65.31.180.195:8001"
SleepInterval = 1

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
	OrchestratorHost = args[1]
end
if args[2] ~= nil then
	SleepInterval = args[2]
end

function ReadHandle(handle)
	local result = ""

	for chunk in handle do result = result..chunk end

	return result
end

function GetID()
	local id = io.open("id", "r")

	if id ~= nil then
		return id:read()
	end

	--- id:close()

	local reqHandle = internet.request(OrchestratorHost .. "/getNewID", nil, nil) --- Get new ID from server
	if reqHandle == nil then
		error("Error encountered while getting a new ID from the orchestration server.")
	end

	local r = ReadHandle(reqHandle)

	local idFile = io.open("id", "w") --- Write ID file

	idFile:write(json.decode(r)["ID"])

	idFile:close()

	return GetID()
end

--- Basic initialization for our main handler loops
function Init()
	print("INFO: Got server host: ", OrchestratorHost)

	--- Set turtleID
	turtleID = GetID()
	print("INFO: Got turtle ID: ", turtleID)
end

--- https://stackoverflow.com/a/7615129
function StrSplit(inputstr, sep)
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
function UpdateStatus(status)
	local reqHandle = internet.request(OrchestratorHost .. "/" .. turtleID .. "/UpdateStatus", json.encode(status))
	if reqHandle == nil then
		print("INFO: Error sending our status to.")
		return -1
	end

	return 0
end

--- Gets the nest task(s) (if any) from the orchestration server
function GetTask()
	local reqHandle = internet.request(OrchestratorHost .. "/" .. turtleID .. "/getTask")
	if reqHandle == nil then
		print("INFO: Error getting task from orchestration server.")
		return -1
	end

	return json.decode(ReadHandle(reqHandle))["Tasks"]
end

--- Loops through each task, and adds it to the task queue
function PopulateTaskQueue(tasks)
	if tasks[1][1] ~= "none" then
		local i = 0

		while i < #tasks do
			table.insert(taskQueue, tasks[i+1])

			i = i + 1
		end
	end
end

--- Checks a local script's version/downloads the latest script
--- Versioning is based off a version string (first line of file)
function DownloadScript(scriptName, versionString)
	local script = io.open(scriptName, "r")

	if script ~= nil then
		local line = script:read("*l")

		if line == versionString then
			print("INFO: ", scriptName, " already latest version")

			io.close(script)

			return 0
		end
	end

	if script ~= nil then
		print("INFO: ", scriptName, " outdated! Redownloading...")
	else
		print("INFO: Downloading script: ", scriptName)
	end

	local reqHandle = internet.request(OrchestratorHost .. "/scripts/" .. scriptName)
	if reqHandle == nil then
		print("INFO: Error retrieving script from orchestration server.")
		return -1
	end

	script = io.open(scriptName, "w")

	script:write(ReadHandle(reqHandle))

	script:close()

	--reqHandle.close()

	return 0
end

--- Pseudo-switch statement for core functions
local switch = {
	["core/GetTask"] = function()
		local tasks = GetTask()
		if tasks ~= -1 then
			PopulateTaskQueue(tasks)
		end

		if taskQueue[2] then --- Nobody should really call this...
			UpdateStatus(taskQueue[1], tasks)			
		end
	end,

	["core/DownloadScript"] = function()
		local resp = DownloadScript(taskQueue[3], taskQueue[4])

		if taskQueue[2] then
			UpdateStatus(taskQueue[1], resp)
		end
	end,

	["core/executeScript"] = function()
		local resp = os.execute("./", taskQueue[3])

		if taskQueue[2] then
			UpdateStatus(taskQueue[1], resp)
		end
	end,

	["core/deleteScript"] = function()
		local resp = os.execute("./delete ", taskQueue[3])

		if taskQueue[2] then
			UpdateStatus(taskQueue[1], resp)
		end
	end
}

--- Constantly pings the orchestration server for new tasks,
--- adds them to the queue, then executes tasks in the task queue
function Main()
	local startTime = (os.time() - SleepInterval * 100)

	while true do
		if #taskQueue > 0 then
			local taskFunction = switch[taskQueue[1]]
			if taskFunction then
				taskFunction()
			else
				local cmdTable = StrSplit(taskQueue[1], " ")

				local resp = DownloadScript(cmdTable[1], cmdTable[3])
				if resp == -1 and taskQueue[2] == true then
					UpdateStatus(taskQueue[1], resp)
				end

				local argTable = table.slice(cmdTable, 2, #cmdTable)

				resp = os.execute("lua " .. cmdTable[1] )--.. argTable)
				if resp == -1 and taskQueue[2] == true then
					UpdateStatus(taskQueue[1], resp)
				end
			end

			table.remove(taskQueue, 1)
		else
			if (os.time() - startTime) / 100 > SleepInterval then
				startTime = os.time()

				local tasks = GetTask()
				if tasks ~= -1 then
					PopulateTaskQueue(tasks)
				end
			else
				os.sleep(SleepInterval - (os.time() - startTime))
			end
		end

		os.sleep(0) --- Yield to force lua's garbage collector to run
	end
end

Init()

Main()
