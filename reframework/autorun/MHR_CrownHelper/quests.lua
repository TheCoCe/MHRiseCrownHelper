local quests = {};
local singletons;

quests.index = 0;

local quest_manager_type_def = sdk.find_type_definition("snow.QuestManager");
local on_changed_game_status = quest_manager_type_def:get_method("onChangedGameStatus");
local get_status_method = quest_manager_type_def:get_method("getStatus");

function quests.update(args)
    local new_quest_status = sdk.to_int64(args[3]);
    if new_quest_status ~= nil then
        if (quests.index < 2 and new_quest_status == 2) or new_quest_status < 2 then
            -- Quest begin
        end

        quests.index = new_quest_status;
    end
end

function quests.Init()
    if singletons.QuestManager == nil then
        log.error("No quest manager");
        return;
    end

    local new_quest_status = get_status_method:call(singletons.QuestManager);
    if new_quest_status == nil then
        log.error("No Quest Status");
        return;
    end

    quests.index = new_quest_status;
end

function quests.InitModule()
    singletons = require("MHR_CrownHelper.singletons");

    quests.Init();

    sdk.hook(on_changed_game_status, 
        function(args) 
            pcall(quests.update, args);
        end, 
        function(retval)
            return retval;
        end
    );
end

return quests;