local allManagersRetrieved = false;
local singletons = require("MHR_CrownHelper.singletons");
local quests = require("MHR_CrownHelper.quests");
local monster_hook = require("MHR_CrownHelper.monster_hook");
local drawing = require("MHR_CrownHelper.drawing");
local time = require("MHR_CrownHelper.time");

-- init modules
singletons.InitModule();
quests.InitModule();
monster_hook.InitModule();

-- sdk
local message_manager_type_def = sdk.find_type_definition("snow.gui.MessageManager");
local get_enemy_name_message_method = message_manager_type_def:get_method("getEnemyNameMessage");

local record_manager_type_def = sdk.find_type_definition("snow.HunterRecordManager");
local record_mini_method = record_manager_type_def:get_method("isSmallCrown");
local record_big_method = record_manager_type_def:get_method("isBigCrown");
local record_king_method = record_manager_type_def:get_method("isKingCrown");

local monsters = {};
local showCrownChanceWindow = true;

local function update()
    singletons.Init();
    time.tick();

    drawing.draw_Crown(1, 0, 0, 48, 48);
    drawing.draw_Crown(2, 48, 0, 48, 48);
    drawing.draw_Crown(3, 96, 0, 48, 48);

    drawing.Update(time.time_delta);

    if quests.index < 2 then
        -- player in village
        showCrownChanceWindow = true;
    elseif quests.index == 2 then
        -- player on quest
        if showCrownChanceWindow then
            if monster_hook.BufferCount() > 0 then
                monsters[#monsters+1] = monster_hook.Pop();
                local monster = monsters[#monsters];

                monster.crown = 0;

                if monster.is_small and not record_mini_method(singletons.HunterRecordManager, monster.id) then
                    monster.crown = 1;
                end

                if monster.is_king and not record_king_method(singletons.HunterRecordManager, monster.id) then
                    monster.crown = 3;
                elseif monster.is_big and not record_big_method(singletons.HunterRecordManager, monster.id) then
                    monster.crown = 2;
                end
            end

            if showCrownChanceWindow and imgui.begin_window("Crown chances:", true, nil) then
                -- fill imgui
                for i = 1, #monsters, 1 do
                    local monster = monsters[i];
    
                    imgui.text(monster.name)
                    imgui.text(string.format("Size: %.5f", monster.size));
    
                    if monster.crown == 1 then
                        imgui.text("Mini crown chance");
                    elseif monster.crown == 2 then
                        imgui.text("Big crown chance");
                    elseif monster.crown == 3 then
                        imgui.text("King crown chance");
                    end

                    imgui.spacing();
                end
            else
                showCrownChanceWindow = false;
            end
        end
    end
end

local function init_d2d()
    -- register fonts and stuff here
    drawing.Init();
end

if d2d ~= nil then
    d2d.register(init_d2d, update);
else
    re.on_frame(update);
end