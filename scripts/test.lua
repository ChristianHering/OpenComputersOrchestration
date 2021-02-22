---v2.0.1

local internet = require("internet") --- Builtin - https://ocdoc.cil.li/api:internet

local resp = internet.request("http://65.31.180.195:8001/ping")
if resp == nil then
    print("Error retrieving script from orchestration server.")
    return -1
end

os.sleep(0)
