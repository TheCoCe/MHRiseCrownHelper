local CrownTracker = {};
local Settings = require("MHR_CrownHelper.Settings");
local Monsters = require("MHR_CrownHelper.Monsters");
local table_helpers = require("MHR_CrownHelper.table_helpers")
local Drawing       = require("MHR_CrownHelper.Drawing")

CrownTracker.crownTableVisible = true;

local windowPosSizeFlags = 1 << 2;
local defaultWindowSize = {-1, 500};
-- ImGuiTableFlags_Resizable | ImGuiTableFlags_Reorderable | ImGuiTableFlags_BordersInnerH |ImGuiTableFlags_BordersInnerV | ImGuiTableFlags_SizingStretchProp
local tableFlags = 1 << 7 | 1 << 9 | 1 << 13 | 1 << 8 | 1 << 10;

local resetWindow = false;

-------------------------------------------------------------------

local function GetDefaultWindowSize()
    return defaultWindowSize;
end

-------------------------------------------------------------------

local function GetDefaultWindowPos()
    local x, y = Drawing.GetWindowSize();
    return {50, y - 50 - defaultWindowSize[2]};
end

-------------------------------------------------------------------

function CrownTracker.ResetWindow()
    resetWindow = true;
end

-------------------------------------------------------------------

local function GetWindowFlags()
    if resetWindow then
        resetWindow = false;
        return 1 << 0;
    end

    return windowPosSizeFlags;
end

-------------------------------------------------------------------

---Draws the crown tracker window
function CrownTracker.DrawCrownTracker()
    if Settings.current.crownTracker.showCrownTracker and CrownTracker.crownTableVisible then
        local flags = GetWindowFlags();
        imgui.set_next_window_size(GetDefaultWindowSize(), flags);
        imgui.set_next_window_pos(GetDefaultWindowPos(), flags);
        if imgui.begin_window("Monster Crown Tracker", CrownTracker.crownTableVisible, 1 << 14 | 1 << 16) then
            CrownTracker.DrawMonsterSizeTable();
            imgui.end_window();
        else
            CrownTracker.crownTableVisible = false;
        end
    end
end

-------------------------------------------------------------------

---Draws the monster size table in an imgui window.
function CrownTracker.DrawMonsterSizeTable()
    
    local tableSize = 4;
    if Settings.current.crownTracker.showSizeBorders then
        tableSize = tableSize + 3;
    end
    if Settings.current.crownTracker.showCurrentRecords then
        tableSize = tableSize + 2;
    end
    

    if imgui.begin_table("Monster Crown Tracker", tableSize, tableFlags) then
        imgui.table_setup_column("Monster");
        imgui.table_setup_column("M");
        imgui.table_setup_column("S");
        imgui.table_setup_column("G");

        if Settings.current.crownTracker.showCurrentRecords then
            imgui.table_setup_column("Min");
            imgui.table_setup_column("Max");
        end

        if Settings.current.crownTracker.showSizeBorders then
            imgui.table_setup_column("MB");
            imgui.table_setup_column("SB");
            imgui.table_setup_column("GB");
        end

        imgui.table_headers_row();

        for _, v in table_helpers.orderedPairs(Monsters.monsterDefinitions) do
            local sizeDetails = Monsters.GetSizeInfoForEnemyType(v.emType, false);

            if sizeDetails ~= nil then
                if not sizeDetails.crownEnabled or (Settings.current.crownTracker.hideComplete and sizeDetails.smallCrownObtained and 
                    sizeDetails.bigCrownObtained and sizeDetails.kingCrownObtained) then
                        goto continue;
                end

                imgui.table_next_row();
                imgui.table_next_column();
                imgui.text(v.name);
                
                imgui.table_next_column();
                if sizeDetails.smallCrownObtained then
                    imgui.text("X");
                end
                
                imgui.table_next_column();
                if sizeDetails.bigCrownObtained then
                    imgui.text("X");
                end
                
                imgui.table_next_column();
                if sizeDetails.kingCrownObtained then
                    imgui.text("X");
                end

                if Settings.current.crownTracker.showCurrentRecords then
                    imgui.table_next_column();
                    imgui.text(string.format("%.0f", sizeDetails.minHuntedSize * 100));
                    
                    imgui.table_next_column();
                    imgui.text(string.format("%.0f", sizeDetails.maxHuntedSize * 100));
                end
                
                if Settings.current.crownTracker.showSizeBorders then
                    imgui.table_next_column();
                    imgui.text(string.format("%.0f", sizeDetails.smallBorder * 100));
                    
                    imgui.table_next_column();
                    imgui.text(string.format("%.0f", sizeDetails.bigBorder * 100));
                    
                    imgui.table_next_column();
                    imgui.text(string.format("%.0f", sizeDetails.kingBorder * 100));
                end
            end

            ::continue::
        end

        imgui.end_table();
    end
end

return CrownTracker;