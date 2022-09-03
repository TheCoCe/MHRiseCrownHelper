local CrownHelper = {};
local Singletons    = require("MHR_CrownHelper.Singletons");
local Quests        = require("MHR_CrownHelper.Quests");
local Monsters      = require("MHR_CrownHelper.Monsters");
local Drawing       = require("MHR_CrownHelper.Drawing");
--local Time = require("MHR_CrownHelper.Time");
local Settings      = require("MHR_CrownHelper.Settings");
local SettingsMenu  = require("MHR_CrownHelper.SettingsMenu");
local Utils         = require("MHR_CrownHelper.Utils");
local CrownTracker  = require("MHR_CrownHelper.CrownTracker");

Settings.InitModule();
CrownHelper.initialized = false;

-- TODO: List:
-- update readme to include proper credits
-- fix non d2d sizeGraph drawing

-------------------------------------------------------------------

function CrownHelper.HandleInit()
    -- Init all singletons
    if not Singletons.isInitialized then
        if Singletons.Init() then
            -- Init modules that require all singletons to be set up
            Quests.InitModule();
        end
    else
        if Quests.gameStatus > 0 then
            -- Init modules that require ingame
            Monsters.InitModule();

            CrownHelper.initialitzed = true;
        end
    end
end

-------------------------------------------------------------------

function CrownHelper.OnFrame()
    -- init
    if not CrownHelper.initialitzed then
        CrownHelper.HandleInit();
    -- player ingame
    else
        -- player in village
        if Quests.gameStatus == 1 then
            CrownTracker.DrawCrownTracker();
        end

        -- player on quest
        if Quests.gameStatus == 2 then
            -- draw size info
            if not d2d and Settings.current.sizeDetails.showSizeDetails then
                Monsters.IterateMonsters(Drawing.DrawMonsterDetails);
            end
        end
    end

    CrownHelper.DrawSettingsMenu();
end

-------------------------------------------------------------------

function CrownHelper.DrawD2D()
    -- player in village
    if Quests.gameStatus < 2 then
    -- player on quests
    elseif Quests.gameStatus == 2 then
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

function CrownHelper.InitD2D()
    -- register fonts and stuff here
    Drawing.Init();
end

-------------------------------------------------------------------

-- init stuff

re.on_draw_ui(function ()
    if imgui.button("MHR Crown Helper") then
        SettingsMenu.isOpened = not SettingsMenu.isOpened;
    end
end)

-------------------------------------------------------------------

function CrownHelper.DrawSettingsMenu()
    if not reframework:is_drawing_ui() then
        SettingsMenu.isOpened = false;
    end

    if SettingsMenu.isOpened then
        pcall(SettingsMenu.Draw);
    end
end

-------------------------------------------------------------------

if d2d ~= nil then
    -- init d2d
    d2d.register(CrownHelper.InitD2D, CrownHelper.DrawD2D);
end

-- init update loop
re.on_frame(CrownHelper.OnFrame);

return CrownHelper;