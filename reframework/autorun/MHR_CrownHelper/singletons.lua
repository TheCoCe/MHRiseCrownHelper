local Singletons = {};
local Utils = require "MHR_CrownHelper.Utils"

Singletons.MessageManager = nil;
Singletons.HunterRecordManager = nil;
Singletons.QuestManager = nil;
Singletons.EnemyManager = nil;
Singletons.SceneManager = nil;
Singletons.GameCamera = nil;
Singletons.GuiManager = nil;
Singletons.GuildCardManager = nil;
Singletons.SnowGameManager = nil;

Singletons.isInitialized = false;

-------------------------------------------------------------------

---Initializes the singleton manager
function Singletons.Init()
    -- initialized flag will be reset if any of the following inits fails
    Singletons.isInitialized = true;

    Singletons.MessageManager = Singletons.InitSingleton("snow.gui.MessageManager");
    Singletons.HunterRecordManager = Singletons.InitSingleton("snow.HunterRecordManager");
    Singletons.QuestManager = Singletons.InitSingleton("snow.QuestManager");
    Singletons.EnemyManager = Singletons.InitSingleton("snow.enemy.EnemyManager");
    Singletons.GameCamera = Singletons.InitSingleton("snow.GameCamera");
    Singletons.GuiManager = Singletons.InitSingleton("snow.gui.GuiManager");
    Singletons.GuildCardManager = Singletons.InitSingleton("snow.GuildCardManager");
    Singletons.SnowGameManager = Singletons.InitSingleton("snow.SnowGameManager");

    Singletons.SceneManager = Singletons.InitSingletonNative("via.SceneManager");

    return Singletons.isInitialized;
end

-------------------------------------------------------------------

---Tries to get a managed singleton.
---@param name string
---@return userdata|nil singleton
function Singletons.InitSingleton(name)
    local singleton = nil;
    
    singleton = sdk.get_managed_singleton(name);
    if singleton == nil then
        --Utils.logError("Singleton " .. name .. " not found!");
    end
    
    Singletons.isInitialized = Singletons.isInitialized and singleton ~= nil;

    return singleton;
end

-------------------------------------------------------------------

---Tries to get a native singleton.
---@param name string
---@return userdata|nil singleton
function Singletons.InitSingletonNative(name)
    local singleton = nil;

    singleton = sdk.get_native_singleton(name);
    if singleton == nil then
        --Utils.logError("Singleton " .. name .. " not found!");
    end

    Singletons.isInitialized = Singletons.isInitialized and singleton ~= nil;

    return singleton;
end

-------------------------------------------------------------------

function Singletons.InitModule() 
    Singletons.Init();
end

-------------------------------------------------------------------

return Singletons;