local rootDir = debug.getinfo(1, "S").source:match("@(.*/)tes3conv(/.*)?") or ""
require(rootDir .. "common/utilities")
require(rootDir .. "common/data")


local tes3conv_exe = IsUNIX and (rootDir .. "tes3conv/tes3conv") or (rootDir .. "tes3conv/tes3conv.exe")
local run_cmd = IsUNIX and "./" or "start "

function ParseESP(esp)
    local output_json = esp:sub(0, -4) .. "json"
    local parse_cmd = run_cmd ..
        tes3conv_exe ..
        " " ..
        dataFilesLoader.config.esp_list ..
        ReformatFile(esp) .. " " .. dataFilesLoader.config.dfl_input .. ReformatFile(output_json)
    Log(1, "Parsing " .. parse_cmd)
    os.execute(parse_cmd)
end

function ParseESPs(esps)
    for _, esp in ipairs(esps) do
        ParseESP(esp)
    end
end
