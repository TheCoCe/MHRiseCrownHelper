local Singletons = require("MHR_CrownHelper.Singletons");
local Quests = require("MHR_CrownHelper.Quests");
local Monsters = require("MHR_CrownHelper.Monsters");
local Drawing = require("MHR_CrownHelper.Drawing");
local Time = require("MHR_CrownHelper.Time");
local Settings = require("MHR_CrownHelper.Settings");
local SettingsMenu = require("MHR_CrownHelper.SettingsMenu")

-- init modules
Singletons.InitModule();
Quests.InitModule();
Monsters.InitModule();
Settings.InitModule();

-- session settings
local crownChancesWindowClosed = false;

-------------------------------------------------------------------

local function Update()
    Singletons.Init();
    Time.Tick();

    -- player in village
    if Quests.index < 2 then
        crownChancesWindowClosed = false;
    -- player on quest
    elseif Quests.index == 2 then
        -- draw imgui window if d2d not available
        if Settings.current.showCrownChancesWindow and d2d == nil then
            if not crownChancesWindowClosed and Drawing.BeginMonsterDetailWindow() then
                -- iterate over all monsters and call DrawMonsterDetails for each one
                Monsters.IterateMonsters(Drawing.DrawMonsterDetails);
                Drawing.EndMonsterDetailWindow();
            else
                crownChancesWindowClosed = true;
            end
        end
    end
end

-------------------------------------------------------------------

local function DrawD2D()
    -- player in village
    if Quests.index < 2 then
    -- player on quests
    elseif Quests.index == 2 then
        -- iterate over all monsters and call DrawMonsterCrown for each one
        if Settings.current.crownIcons.showCrownIcons then
            Monsters.IterateMonsters(Drawing.DrawMonsterCrown);
        end
        if Settings.current.sizeDetails.showSizeDetails then
            Monsters.IterateMonsters(Drawing.DrawMonsterDetails);
        end
    end
end

-------------------------------------------------------------------

local function InitD2D()
    -- register fonts and stuff here
    Drawing.Init();
end

-------------------------------------------------------------------

-- inti stuff

re.on_draw_ui(function ()
    if imgui.button("MHR Crown Helper") then
        SettingsMenu.isOpened = not SettingsMenu.isOpened;
    end
end)

re.on_frame(function()
    if not reframework:is_drawing_ui() then
        SettingsMenu.isOpened = false;
    end

    if SettingsMenu.isOpened then
        pcall(SettingsMenu.Draw);
    end
end);

-- init d2d
if d2d ~= nil then
    d2d.register(InitD2D, DrawD2D);
end

-- init update loop
re.on_frame(Update);