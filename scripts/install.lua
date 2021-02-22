local internet = require("internet") --- Builtin - https://ocdoc.cil.li/api:internet

-- Writes "data" string to file "fileName"
function WriteFile(fileName, data)
    local script = io.open(fileName, "w")

    script:write(data)

    script:close()
end

-- Returns the body of an HTTP request from a handle
function ReadHandle(handle)
	local result = ""

	for chunk in handle do result = result..chunk end

	return result
end

-- Downloads a file/script
function DownloadScript(scriptName)
    local reqHandle = internet.request(OrchestratorHost .. "/scripts/" .. scriptName)
    if reqHandle == nil then
        print("INFO: Error retrieving script from orchestration server.")
        return -1
    end

    WriteFile(scriptName, ReadHandle(reqHandle))
end
