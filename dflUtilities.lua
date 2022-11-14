local isUNIX = os.getenv("HOME") ~= nil

function log(stream, msg)
    if stream >= 3 then io.stderr:write(msg) else io.stdout:write(msg) end
end

function listFiles(filepath)
    local list_cmd = isUNIX and ("ls -a " .. filepath) or ("dir " .. filepath)
    local pfile = io.popen(list_cmd)
    return pfile and pfile:lines() or {}
end

function getCaseInsensitiveFilename(filepath, filename)
    for _, file in ipairs(listFiles(filepath)) do
        if file:lower() == filename:lower() then
            return file
        end
    end
    return nil
end

function caseSensitiveFormatting(fileList)
    for i, file in ipairs(fileList) do
        fileList[i] = getCaseInsensitiveFilename(dataFilesLoader.config.dfl_input, file)
    end
    return fileList
end
