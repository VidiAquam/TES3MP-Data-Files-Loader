local isUNIX = os.getenv("HOME") ~= nil

local function path(file)
    return file:match("(.*)/.?") or "" -- assumes that all filepaths follow the UNIX format
end

local function basename(file)
    return file:match(".*/(.*)$") or file -- assumes that all filepaths follow the UNIX format
end

--- Log a message in the output or error stream
-- @param stream is the tes3mp ``enumerations.log`` int determining log severity
-- @param msg is the message to be loaded into the stream
function Log(stream, msg)
    msg = msg .. "\n"
    if stream >= 3 then io.stderr:write(msg) else io.stdout:write(msg) end
end

--- List all the files in a given filepath
-- @param filepath ist he filepath
-- @return the list of files found
function ListFiles(filepath)
    local list_cmd = isUNIX and ("ls -a " .. filepath) or ("dir " .. filepath)
    local pfile = io.popen(list_cmd)
    return pfile and pfile:lines() or {}
end

--- Gets the file name as it is in the filesystem
-- @param filepath is the filepath to the filename
-- @param filename is the case *insensitive* filename
-- @return the case sensitive filename
local function getCaseInsensitiveFilename(filepath, filename)
    for _, file in ipairs(ListFiles(filepath)) do
        if file:lower() == filename:lower() then
            return file
        end
    end
    return nil -- Didn't exist in the filepath or there are no files in the filepath
end

--- Finds the file's name in the filesystem
-- @param fileList are the list of files (paths and basenames)
-- @return the list of filepaths
function CaseSensitiveFormatting(fileList)
    for i, file in ipairs(fileList) do
        local filepath = path(file)
        local filename = basename(file)
        fileList[i] = getCaseInsensitiveFilename(filepath, filename)
    end
    return fileList
end
