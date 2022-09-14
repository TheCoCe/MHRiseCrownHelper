local CrownHelper = {};
local Singletons            = require("MHR_CrownHelper.Singletons");
local Quests                = require("MHR_CrownHelper.Quests");
local Monsters              = require("MHR_CrownHelper.Monsters");
local Drawing               = require("MHR_CrownHelper.Drawing");
local Time                  = require("MHR_CrownHelper.Time");
local Settings              = require("MHR_CrownHelper.Settings");
local SettingsMenu          = require("MHR_CrownHelper.SettingsMenu");
local NativeSettingsMenu    = require("MHR_CrownHelper.NativeSettingsMenu");
local Utils                 = require("MHR_CrownHelper.Utils");
local CrownTracker          = require("MHR_CrownHelper.CrownTracker");
local SizeGraph             = require("MHR_CrownHelper.SizeGraph");

Settings.InitModule();
NativeSettingsMenu.InitModule();
CrownHelper.initialized = false;

-- TODO: List:
-- fix non d2d sizeGraph drawing
-- add icon when the record is already registered but better than the previously registered one
-- fix size graph not crrectly showing when a monster leaves and a new one joins while size graph was hidden

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
            SizeGraph.InitModule();
            CrownHelper.initialitzed = true;
        end
    end
end

-------------------------------------------------------------------

function CrownHelper.OnFrame()
    -- frame time currently unused -> no need to tick
    Time.Tick();
    
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
            Monsters.Update(Time.timeDelta);
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
    Time.D2DTick();
    if Quests.gameStatus == 2 then
        SizeGraph.Update(Time.timeDeltaD2D);
    end
    Drawing.Update(Time.timeDeltaD2D);
end

-------------------------------------------------------------------

function CrownHelper.InitD2D()
    -- register fonts and stuff here
    Drawing.InitModule();
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