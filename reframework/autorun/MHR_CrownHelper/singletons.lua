local Singletons = {};

Singletons.MessageManager = nil;
Singletons.HunterRecordManager = nil;
Singletons.QuestManager = nil;
Singletons.EnemyManager = nil;
Singletons.SceneManager = nil;

-------------------------------------------------------------------

function Singletons.Init() 
    Singletons.MessageManager = Singletons.InitSingleton("snow.gui.MessageManager");
    Singletons.HunterRecordManager = Singletons.InitSingleton("snow.HunterRecordManager");
    Singletons.QuestManager = Singletons.InitSingleton("snow.QuestManager");
    Singletons.EnemyManager = Singletons.InitSingleton("snow.enemy.EnemyManager");
    
    Singletons.SceneManager = Singletons.InitSingletonNative("via.SceneManager");
end

-------------------------------------------------------------------

function Singletons.InitSingleton(name)
    local singleton = nil;

    singleton = sdk.get_managed_singleton(name);
    if singleton == nil then
        log.error("[MHR CrownHelper] singleton '" .. name .. "' not found");
    end

    return singleton;
end

-------------------------------------------------------------------

function Singletons.InitSingletonNative(name)
    local singleton = nil;

    singleton = sdk.get_native_singleton(name);
    if singleton == nil then
        log.error("[MHR CrownHelper] singleton '" .. name .. "' not found");
    end

    return singleton;
end

-------------------------------------------------------------------

function Singletons.InitModule() 
    Singletons.Init();
end

-------------------------------------------------------------------

return Singletons;