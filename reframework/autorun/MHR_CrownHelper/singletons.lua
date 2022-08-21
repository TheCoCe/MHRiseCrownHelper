local singletons = {};

singletons.MessageManager = nil;
singletons.HunterRecordManager = nil;
singletons.QuestManager = nil;
singletons.EnemyManager = nil;
singletons.SceneManager = nil;

function singletons.Init() 
    singletons.MessageManager = singletons.InitSingleton("snow.gui.MessageManager");
    singletons.HunterRecordManager = singletons.InitSingleton("snow.HunterRecordManager");
    singletons.QuestManager = singletons.InitSingleton("snow.QuestManager");
    singletons.EnemyManager = singletons.InitSingleton("snow.enemy.EnemyManager");
    
    singletons.SceneManager = singletons.InitSingletonNative("via.SceneManager");
end

function singletons.InitSingleton(name)
    local singleton = nil;

    singleton = sdk.get_managed_singleton(name);
    if singleton == nil then
        log.error("[MHR CrownHelper] singleton '" .. name .. "' not found");
    end

    return singleton;
end

function singletons.InitSingletonNative(name)
    local singleton = nil;

    singleton = sdk.get_native_singleton(name);
    if singleton == nil then
        log.error("[MHR CrownHelper] singleton '" .. name .. "' not found");
    end

    return singleton;
end

function singletons.InitModule() 
    singletons.Init();
end

return singletons;