IsUNIX = os.getenv("HOME") ~= nil

local function path(file)
    return file:match("(.*)/.?") or "" -- assumes that all filepaths follow the UNIX format
end

local function basename(file)
    return file:match(".*/(.*)$") or file -- assumes that all filepaths follow the UNIX format
end

local function getLogDetail(stream)
    local details = {
        [0] = "SCRIPT",
        [1] = "INFO",
        [2] = "WARN",
        [3] = "ERROR",
        [4] = "FATAL"
    }
    return details[stream]
end

--- Log a message in the output or error stream
-- @param stream is the tes3mp ``enumerations.log`` int determining log severity
-- @param msg is the message to be loaded into the stream
function Log(stream, msg)
    local detail = getLogDetail(stream)
    msg = "[" .. detail .. "]: " .. msg .. "\n"
    if stream >= 3 then io.stderr:write(msg) else io.stdout:write(msg) end
end

--- Replaces spaces with underscores in file
-- @param file (inc. path) to replace name of
-- @return reformatted file
-- TODO: May not need to reformat if on windows
function ReformatFile(file)
    return file:gsub(" ", "\\ "):gsub("%(", "\\("):gsub("%)", "\\)")
end

--- List all the files in a given filepath
-- @param filepath ist he filepath
-- @return the list of files found
function ListFiles(filepath)
    local list_cmd = IsUNIX and ("ls " .. filepath) or ("dir " .. filepath)
    local pfile = io.popen(list_cmd)
    return pfile and pfile:lines() or {}
end

--- Gets the file name as it is in the filesystem
-- @param filepath is the filepath to the filename
-- @param filename is the case *insensitive* filename
-- @return the case sensitive filename
local function getCaseInsensitiveFilename(filepath, filename)
    for file in ListFiles(filepath) do
        if file:lower() == filename:lower() then
            return file
        end
    end
    return nil -- Didn't exist in the filepath or there are no files in the filepath
end

--- Finds the file's name in the filesystem
-- @param fileList are the list of files (paths and basenames)
-- @return the list of filepaths
function CaseSensitiveFiles(fileList)
    for i, file in ipairs(fileList) do
        local filepath = path(file)
        local filename = basename(file)
        fileList[i] = getCaseInsensitiveFilename(filepath, filename)
    end
    return fileList
end

--- Checks if a table contains a value
-- @param table is the table being checked for containing a value
-- @param value is the value that is being checked for. Value can be a table, a regex string or any primitive
-- @return true if the value exists within the table
function ContainsValue(table, value)
    for _, v in pairs(table) do
        if type(v) == "table" then
            ContainsValue(v, value)
        elseif type(v) == "string" and type(value) == "string" then
            if v:match(value) ~= nil then return true end
        else
            if v == value then return true end
        end
    end
    return false
end
