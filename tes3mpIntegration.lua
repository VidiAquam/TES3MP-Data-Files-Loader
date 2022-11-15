require("custom/dfl/dataFilesLoader")

customEventHooks.registerHandler("OnServerPostInit", function()
    if dataFilesLoader.config.parseOnServerStart then
        dataFilesLoader.generateDFLFiles()
    end
    dataFilesLoader.loadDFLFiles()
end)
