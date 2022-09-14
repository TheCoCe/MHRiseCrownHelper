local Quests = {};
local Singletons    = require("MHR_CrownHelper.Singletons");
local Event         = require("MHR_CrownHelper.Event");
local Utils         = require("MHR_CrownHelper.Utils");

Quests.gameStatus = -1;

local questManagerTypeDef = sdk.find_type_definition("snow.QuestManager");
local onChangedGameStatus = questManagerTypeDef:get_method("onChangedGameStatus");

local snowGameManagerTypeDef = sdk.find_type_definition("snow.SnowGameManager");
local getCurrentStatus = snowGameManagerTypeDef:get_method("get_CurrentStatus");

Quests.onGameStatusChanged = Event.New();

-------------------------------------------------------------------

---The update hook function for the
---@param args any
function Quests.OnGameStatusChangedHook(args)
    local newQuestStatus = sdk.to_int64(args[3]);
    if newQuestStatus ~= nil then
        -- invoke quest status changed event
        if newQuestStatus ~= Quests.gameStatus then
            Quests.gameStatus = newQuestStatus;
            Quests.onGameStatusChanged(Quests.gameStatus);
        end

    end
end

-------------------------------------------------------------------

---Initializes the Quest state
function Quests.Init()
    if Singletons.QuestManager == nil then
        Utils.logError("(Quests) No Quest Manager");
        return;
    end

    local newQuestStatus = getCurrentStatus(Singletons.SnowGameManager);
    if newQuestStatus ~= nil then
        Quests.gameStatus = newQuestStatus;
        Quests.onGameStatusChanged(newQuestStatus);
    else
        Utils.logError("(Quests) No Game Status");
        return;
    end
end

-------------------------------------------------------------------

function Quests.InitModule()
    Quests.Init();

    sdk.hook(onChangedGameStatus,
        function(args)
            pcall(Quests.OnGameStatusChangedHook, args);
        end,
        function(retval)
            return retval;
        end
    );
end

return Quests;
