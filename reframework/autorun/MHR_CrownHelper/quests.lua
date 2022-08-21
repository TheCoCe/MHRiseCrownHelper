local Quests = {};
local Singletons = require("MHR_CrownHelper.Singletons");
local Monsters = require("MHR_CrownHelper.Monsters");

Quests.index = 0;

local questManagerTypeDef = sdk.find_type_definition("snow.QuestManager");
local onChangedGameStatus = questManagerTypeDef:get_method("onChangedGameStatus");
local getStatusMethod = questManagerTypeDef:get_method("getStatus");

-------------------------------------------------------------------

function Quests.Update(args)
    local newQuestStatus = sdk.to_int64(args[3]);
    if newQuestStatus ~= nil then
        if (Quests.index < 2 and newQuestStatus == 2) or newQuestStatus < 2 then
            -- Quest begin

            -- clear monster list from last quest
            Monsters.InitList();
        end

        Quests.index = newQuestStatus;
    end
end

-------------------------------------------------------------------

function Quests.Init()
    if Singletons.QuestManager == nil then
        log.error("No quest manager");
        return;
    end

    local newQuestStatus = getStatusMethod:call(Singletons.QuestManager);
    if newQuestStatus == nil then
        log.error("No Quest Status");
        return;
    end

    Quests.index = newQuestStatus;
end

-------------------------------------------------------------------

function Quests.InitModule()
    Quests.Init();

    sdk.hook(onChangedGameStatus, 
        function(args) 
            pcall(Quests.Update, args);
        end, 
        function(retval)
            return retval;
        end
    );
end

-------------------------------------------------------------------

return Quests;