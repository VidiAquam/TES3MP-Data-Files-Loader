fileHelperDFL = {}

-- Determines if the OS is a UNIX-based system
fileHelperDFL.isUNIX = function ()
    return os.getenv("HOME") ~= nil
end

-- Gets a list of filenames in the root of the path
fileHelperDFL.dir = function(path) 
    local i, t, popen = 0, {}, io.popen
    -- Windows users "UserProfile" -> 
    local list_command = fileHelperDFL.isUNIX() and 'ls "'..path..'"' or 'dir "'..path..'" /b /ad'
    local pfile = popen(list_command)
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end