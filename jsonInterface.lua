local rootDir = debug.getinfo(1, "S").source:match("@(.*/)") or ""
require(rootDir .. "common/utilities")

local dkjson = require("dkjson")
local cjson
local cjsonExists = pcall(require, "cjson") -- Hacky way of checking if module exists

if cjsonExists then
    cjson = require("cjson")
    cjson.encode_sparse_array(true)
    cjson.encode_invalid_numbers("null")
    cjson.encode_empty_table_as_object(false)
    -- cjson.decode_null_as_lightuserdata(false)
else
    Log(3,
        "Could not find Lua CJSON! The decoding and encoding of JSON files will always use dkjson and be slower as a result.")
end

local jsonInterface = {}

jsonInterface.libraryMissingMessage = "No input/output library selected for JSON interface!"

function jsonInterface.setLibrary()
    if IsUNIX then
        jsonInterface.ioLibrary = io
    else
        jsonInterface.ioLibrary = require("io2")
    end
end

-- Remove all text from before the actual JSON content starts
function jsonInterface.removeHeader(content)

    local closestBracketIndex

    local bracketIndex1 = content:find("\n%[")
    local bracketIndex2 = content:find("\n{")

    if bracketIndex1 and bracketIndex2 then
        closestBracketIndex = math.min(bracketIndex1, bracketIndex2)
    else
        closestBracketIndex = bracketIndex1 or bracketIndex2
    end

    return content:sub(closestBracketIndex)
end

function jsonInterface.load(fileName)

    if jsonInterface.ioLibrary == nil then
        jsonInterface.setLibrary()
    end

    local file = jsonInterface.ioLibrary.open(fileName, 'r')

    if file ~= nil then
        local content = file:read("*all")
        file:close()

        if cjsonExists then
            -- Lua CJSON does not support comments before the JSON data, so remove them if
            -- they are present
            if content:sub(1, 2) == "//" then
                content = jsonInterface.removeHeader(content)
            end

            local decodedContent
            local status, result = pcall(function() decodedContent = cjson.decode(content) end)

            if status then
                return decodedContent
            else
                Log(3, "Could not load " .. fileName .. " using Lua CJSON " ..
                    "due to improperly formatted JSON! Error:\n" .. result .. "\n" .. fileName .. " is being read " ..
                    "via the slower dkjson instead.")
            end
        end

        return dkjson.decode(content)
    else
        return nil
    end
end

function jsonInterface.writeToFile(fileName, content)

    if jsonInterface.ioLibrary == nil then
        Log(3, jsonInterface.libraryMissingMessage)
        return false
    end

    local file = jsonInterface.ioLibrary.open(fileName, 'w+b')

    if file ~= nil then
        file:write(content)
        file:close()
        return true
    else
        return false
    end
end

-- Save data to JSON in a slower but human-readable way, with identation and a specific order
-- to the keys, provided via dkjson
function jsonInterface.save(fileName, data, keyOrderArray)

    local content = dkjson.encode(data, { indent = true, keyorder = keyOrderArray })

    return jsonInterface.writeToFile(fileName, content)
end

-- Save data to JSON in a fast but minimized way, provided via Lua CJSON, ideal for large files
-- that need to be saved over and over
function jsonInterface.quicksave(fileName, data)

    if cjsonExists then
        local content = cjson.encode(data)
        return jsonInterface.writeToFile(fileName, content)
    else
        return jsonInterface.save(fileName, data)
    end
end

return jsonInterface
