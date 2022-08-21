local singletons = require("MHR_CrownHelper.singletons");
local quests = require("MHR_CrownHelper.quests");
local monster_hook = require("MHR_CrownHelper.monster_hook");
local drawing = require("MHR_CrownHelper.drawing");
local time = require("MHR_CrownHelper.time");

-- init modules
singletons.InitModule();
quests.InitModule();
monster_hook.InitModule();

-- config
local showCrownChanceWindow = true;
local showCrownIcons = true;

local function Update()
    singletons.Init();
    time.tick();

    -- player in village
    if quests.index < 2 then
        showCrownChanceWindow = true;
    -- player on quest
    elseif quests.index == 2 then
        -- draw imgui window if d2d not available
        if showCrownChanceWindow and d2d == nil then
            if showCrownChanceWindow and drawing.BeginMonsterDetailWindow() then
                -- iterate over all monsters and call DrawMonsterDetails for each one
                monster_hook.InterateMonsters(drawing.DrawMonsterDetails);
                drawing.EndMonsterDetailWindow();
            else
                showCrownChanceWindow = false;
            end
        end
    end
end

local function DrawD2D()
    -- player in village
    if quests.index < 2 then
    -- player on quests
    elseif quests.index == 2 then
        -- iterate over all monsters and call DrawMonsterCrown for each one
        if showCrownIcons then
            monster_hook.InterateMonsters(drawing.DrawMonsterCrown);
            monster_hook.InterateMonsters(drawing.DrawMonsterDetails);
        end
    end
end

local function InitD2D()
    -- register fonts and stuff here
    drawing.Init();
end

-- init d2d
if d2d ~= nil then
    d2d.register(InitD2D, DrawD2D);
end

-- init update loop
re.on_frame(Update);