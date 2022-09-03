local Settings = {};
local TableHelpers = require("MHR_CrownHelper.table_helpers");

Settings.current = nil;
Settings.configFileName = "MHR_CrownHelper/Settings.json";
Settings.default = {};

-------------------------------------------------------------------

---Initializes the default settings
function Settings.Init()
    Settings.default = {
        crownIcons = {
            showCrownIcons = true,
            showHunterRecordIcons = true,
            
            crownIconSizeMultiplier = 1,
            crownIconOffset = {
                x = 0,
                y = 0
            },

            hunterRecordIconSizeMultiplier = 1,
            hunterRecordIconOffset = {
                x = 0,
                y = 0
            }
        },

        sizeDetails = {
            showSizeDetails = true,
            showHunterRecordIcons = true,
            showSizeGraph = true,

            sizeDetailsOffset = {
                x = 0,
                y = 0,
            }
        },

        crownTracker = {
            showCrownTracker = true,
            hideComplete = true,
            showSizeBorders = false,
            showCurrentRecords = false
        },

        text = {
            textSize = 14,
        }
    };
end

-------------------------------------------------------------------

---Loads the settings file
function Settings.Load()
    local loadedConfig = json.load_file(Settings.configFileName);
    if loadedConfig ~= nil then
        Settings.current = TableHelpers.merge(Settings.default, loadedConfig);
    else
        Settings.current = TableHelpers.deep_copy(Settings.default, nil);
    end
end

-------------------------------------------------------------------

---Saves the settings file
function Settings.Save()
    local success = json.dump_file(Settings.configFileName, Settings.current);
    if success then
        log.info("[MHR CrownHelper] Settings saved successfully");
    else
        log.error("[MHR CrownHelper] Failed to save settings");
    end
end

-------------------------------------------------------------------

function Settings.InitModule()
    Settings.Init();
    Settings.Load();
end

-------------------------------------------------------------------

return Settings;