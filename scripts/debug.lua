local args = { ... }

local execute = args[1]

os.execute("del o")

os.execute("wget http://65.31.180.195:8001/scripts/o.lua o")

if execute == "true" then
	os.execute("o")
end
