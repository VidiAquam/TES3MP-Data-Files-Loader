dataFilesLoader.updateCellRefs = function(cellDescription, oldCell, newCellTable) 
    if newCellTable ~= nil and tes3mp.DoesFileExist(config.dataPath .. "/cell/".. cellDescription .. ".json") then
        serverCellInfo = jsonInterface.load("cell/".. cellDescription)
        if serverCellInfo.lastVisit ~= {} then -- Check for a cell having been reset with Urm's cell reset script; if so, don't bother with it
            


        end
    end
end