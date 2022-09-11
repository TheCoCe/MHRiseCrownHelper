local SizeGraph = {};
local SizeGraphWidget = {};
local Animation     = require("MHR_CrownHelper.Animation");
local Utils         = require("MHR_CrownHelper.Utils")
local Drawing       = require("MHR_CrownHelper.Drawing")
local Monsters      = require("MHR_CrownHelper.Monsters");
local Settings      = require("MHR_CrownHelper.Settings");
local Quests        = require("MHR_CrownHelper.Quests");
local Singletons    = require("MHR_CrownHelper.Singletons")

-------------------------------------------------------------------

-- tgCamera gui visibility
local getTgCameraHudMethod = sdk.find_type_definition("snow.gui.GuiManager"):get_method("get_refGuiHud_TgCamera");
local getTgCameraHudComponentMethod = sdk.find_type_definition("via.gui.PlayObject"):get_method("get_Component");
local getTgCameraHudEnabled = sdk.find_type_definition("via.gui.GUI"):get_method("get_Enabled");
local tgCamGuiComponent;
local guiTgCameraVisible = false;

-------------------------------------------------------------------

local sizeGraphVisible = false;
local sizeGraphAnimating = false;

local TargetCamVisibleFlag = false;

local SizeGraphMonsterList = {};
local SizeGraphWidgets = {};
local MonstersToAdd = {};
local MonstersToRemove = {};

-------------------------------------------------------------------

---Target camera gui visibility changed callback
---@param vis boolean
function SizeGraph.OnGuiTgCameraVisibilityChanged(vis)
    if Quests.gameStatus == 2 then
        if vis and not TargetCamVisibleFlag then
            TargetCamVisibleFlag = true;
            SizeGraph.SizeGraphOpen();
        end
    end
end

-------------------------------------------------------------------

---Game status changed callback
---@param state number
function SizeGraph.OnGameStatusChanged(state)
    if state < 2 then
        TargetCamVisibleFlag = false;
        SizeGraphMonsterList = {};
        MonstersToRemove = {};
        MonstersToAdd = {};
        SizeGraphWidget = {};
    elseif state == 2 then
        -- reset tgCamGuiComponent (no longer valid)
        tgCamGuiComponent = nil;
        -- start delay for size details auto hide
        if Settings.current.sizeDetails.autoHideAfter > 0 then
            Animation.Delay(Settings.current.sizeDetails.autoHideAfter, function()
                SizeGraph.SizeGraphClose();
            end)
        end
    end
end

-------------------------------------------------------------------

---Opens the size graph
function SizeGraph.SizeGraphOpen()
    sizeGraphVisible = true;
    sizeGraphAnimating = true;

    local i = 1;
    local showNextItem = function(f)
        if i <= #SizeGraphMonsterList then
            local Widget = SizeGraphWidgets[SizeGraphMonsterList[i]];
            if not Widget.AnimData.visible then
                Widget:Show();
            end
            Animation.Delay(0.1, function()
                i = i + 1;
                f(f);
            end);
        else
            sizeGraphAnimating = false;
        end
    end

    showNextItem(showNextItem);
end

-------------------------------------------------------------------

---Closes the size graph
function SizeGraph.SizeGraphClose()
    local i = #SizeGraphMonsterList;
    sizeGraphAnimating = true;
    
    local hideNextItem = function(f)
        if i >= 1 then
            local Widget = SizeGraphWidgets[SizeGraphMonsterList[i]];
            if Widget.AnimData.visible then
                Widget:Hide();
            end
            Animation.Delay(0.1, function()
                i = i - 1;
                f(f);
            end)
        else
            sizeGraphVisible = false;
            sizeGraphAnimating = false;
        end
    end
    
    hideNextItem(hideNextItem);
end

-------------------------------------------------------------------

---Update loop
---@param deltaTime number
function SizeGraph.Update(deltaTime)

    -- get tgCamera component if current is invalid
    if not tgCamGuiComponent and Singletons.GuiManager then
        local guiHud_tgCam = getTgCameraHudMethod(Singletons.GuiManager);
        if guiHud_tgCam then
            local root = guiHud_tgCam:get_field("_Root");
            if root then
                tgCamGuiComponent = getTgCameraHudComponentMethod(root);
            end
        end
    end

    -- update tgCamera visibility and invoke event
    if tgCamGuiComponent then
        local visibility = getTgCameraHudEnabled(tgCamGuiComponent);
        if visibility ~= guiTgCameraVisible then
            guiTgCameraVisible = visibility;
            SizeGraph.OnGuiTgCameraVisibilityChanged(guiTgCameraVisible);
        end
    end

    -- add/remove new monsters to size graph
    if TargetCamVisibleFlag then
        if #MonstersToAdd > 0 then
            if sizeGraphVisible then
                if not sizeGraphAnimating then
                    SizeGraphMonsterList[#SizeGraphMonsterList + 1] = MonstersToAdd[1];
                    table.remove(MonstersToAdd, 1);
                    local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                    SizeGraphWidgets[monster] = SizeGraphWidget.New();
                    SizeGraphWidgets[monster]:show(5);
                end
            else
                SizeGraphMonsterList[#SizeGraphMonsterList + 1] = MonstersToAdd[1];
                table.remove(MonstersToAdd, 1);
                local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                SizeGraphWidgets[monster] = SizeGraphWidget.New();

                SizeGraph.SizeGraphOpen();
            end
        end

        if #MonstersToRemove > 0 then
            if sizeGraphVisible then
                if not sizeGraphAnimating then
                    for i = 1, #SizeGraphMonsterList, 1 do
                        if SizeGraphMonsterList[i] == MonstersToRemove[1] then
                            local monster = MonstersToRemove[1];
                            SizeGraphWidgets[monster]:hide(5, function()
                                table.remove(SizeGraphMonsterList, i);
                                SizeGraphWidgets[monster] = nil;
                            end)

                            table.remove(MonstersToRemove, 1);
                            break;
                        end
                    end
                end
            else
                -- remove
                for i = 1, #SizeGraphMonsterList, 1 do
                    if SizeGraphMonsterList[i] == MonstersToRemove[1] then
                        table.remove(SizeGraphMonsterList, i);
                        table.remove(MonstersToRemove, i);
                        break;
                    end
                end
            end
        end
    end
    
    -- draw in quest infos
    if Quests.gameStatus == 2 then
        -- iterate over all monsters and call DrawMonsterCrown for each one
        if Settings.current.crownIcons.showCrownIcons then
            if guiTgCameraVisible then
                Monsters.IterateMonsters(SizeGraph.DrawMonsterCrown);
            end
        end
        if Settings.current.sizeDetails.showSizeDetails then
            if guiTgCameraVisible then
                -- Monsters.IterateMonsters(Drawing.DrawMonsterDetails);
                for i = 1, #SizeGraphMonsterList, 1 do
                    SizeGraph.DrawMonsterDetails(SizeGraphMonsterList[i], i - 1);
                end
            end
        end
    end

end

-------------------------------------------------------------------

local ctPadRight = 0.01953125;      --  50
local ctPadTop = 0.0243056;         --  35
local ctItemWidth = 0.0449;         -- 115
local ctPadItem = 0.006;            --  18
local ctPadItemBotom = 0.0104167;   --  15
local ctInfoHeight = 0.029167;      --  42

---Draws a crown on top of a monster icon in the top right.
---@param monster table
---@param index number
function SizeGraph.DrawMonsterCrown(monster, index)
    if (monster.isSmall or monster.isBig or monster.isKing) then
        local w, h = Drawing.GetWindowSize();

        -- crown size
        local size = (ctItemWidth * w) * 0.5 * Settings.current.crownIcons.crownIconSizeMultiplier;

        -- place crowns on icon
        local posx = (ctPadRight * w) + (index + 1) * (ctItemWidth * w) + index * (ctPadItem * w);
        local posy = (ctPadTop * h) + (ctItemWidth * w) - (size * 1.1);

        -- transform position
        posx, posy = Drawing.FromTopRight(posx, posy);

        posx = posx + Settings.current.crownIcons.crownIconOffset.x;
        posy = posy + Settings.current.crownIcons.crownIconOffset.y;

        --[[
            local image = "miniCrown";
            if monster.isKing then
                image = "kingCrown";
            elseif monster.isBig then
                image = "bigCrown";
            end
        ]]

        local image = monster.isKing and "kingCrown" or (monster.isBig and "bigCrown" or "miniCrown");
        Drawing.DrawImage(Drawing.imageResources[image], posx, posy, size, size);

        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        -- draw book icon
        if (sizeInfo and sizeInfo.crownNeeded) and Settings.current.crownIcons.showHunterRecordIcons then
            size = (ctItemWidth * w) * 0.5 * Settings.current.crownIcons.hunterRecordIconSizeMultiplier;
            posx = (ctPadRight * w) + (index) * (ctItemWidth * w) + index * (ctPadItem * w) + (size * 1.1);
            posy = (ctPadTop * h) + (ctItemWidth * w) - (size * 1.1);
            -- transform position
            posx, posy = Drawing.FromTopRight(posx, posy);

            posx = posx + Settings.current.crownIcons.hunterRecordIconOffset.x;
            posy = posy + Settings.current.crownIcons.hunterRecordIconOffset.y;

            Drawing.DrawImage(Drawing.imageResources["book"], posx, posy, size, size);
        end
    end
end

-------------------------------------------------------------------

local detailInfoSize = 80;

---Draws the monster details for a specific monster
---@param monster table The monster table
---@param index integer The index used for positioning of the graph
function SizeGraph.DrawMonsterDetails(monster, index)
    if not sizeGraphVisible then return; end

    local headerString = monster.name .. ": ";

    local crownString = nil;

    if monster.isSmall then
        crownString = "Mini";
    elseif monster.isKing then
        crownString = "Gold";
    elseif monster.isBig then
        crownString = "Silver";
    end

    if crownString ~= nil then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if (sizeInfo and sizeInfo.crownNeeded) and Settings.current.sizeDetails.showHunterRecordIcons then
            headerString = headerString .. crownString .. " 📙";
        else
            headerString = headerString .. crownString;
        end
    end

    local w, h = Drawing.GetWindowSize();
    local posx = (ctPadRight * w) + 3 * (ctItemWidth * w) + 2 * (ctPadItem * w);
    local posy = (ctPadTop * h) + (ctItemWidth * w) + 2 * (ctPadItemBotom * h) + (ctInfoHeight * h) +
        (detailInfoSize * index);

    local SizeGraphWidget = SizeGraphWidgets[monster];
    
    posx, posy = Drawing.FromTopRight(posx, posy);
    posx = posx + Settings.current.sizeDetails.sizeDetailsOffset.x + SizeGraphWidget.AnimData.offset.x; --animData.offset.x;
    posy = posy + Settings.current.sizeDetails.sizeDetailsOffset.y + SizeGraphWidget.AnimData.offset.y;

    -- Draw the following:
    -- Monster name
    --                    114
    -- 90 ├────────────┼──♛───┤ 123
    
    Drawing.DrawText(headerString, posx, posy, SizeGraphWidget.AnimData.textColor, true, 1.5, 1.5,
        SizeGraphWidget.AnimData.textShadowColor);
        
    local _, height = Drawing.MeasureText(headerString);

    posy = posy + height * 1.5;
    if Settings.current.sizeDetails.showSizeGraph then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if sizeInfo ~= nil then
            SizeGraphWidget:draw(posx, posy, ((3 * ctItemWidth * w) + (2 * ctPadItem * w)), 15, 2, 
                monster.size, sizeInfo.smallBorder, sizeInfo.bigBorder, sizeInfo.kingBorder);
        end
    else
        Drawing.DrawText("Size: " .. string.format("%.0f", monster.size * 100), posx, posy,
            SizeGraphWidget.AnimData.textColor, true, 1.5, 1.5,
            SizeGraphWidget.AnimData.textShadowColor);
    end
end

-------------------------------------------------------------------
-- Size Graph Widget
-------------------------------------------------------------------

---Shows the size graph via an animation
---@param s table
---@param showTime number
---@param callback function
function SizeGraphWidget.ShowAnim(s, showTime, callback)
    s.AnimData.visible = true;
    showTime = showTime or 0.25;

    Animation.AnimLerp(0, 1, showTime, function (v)
        local col1 = Animation.LerpColor(0x00FFFFFF, 0xFFFFFFFF, v);
        local col2 = Animation.LerpColor(0x003f3f3f, 0xFF3f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * v;
    end)

    Animation.AnimLerpV2(500, 0, 0, 0, showTime, function (x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeInQuad");
    
    Animation.Delay(showTime, callback);
end

-------------------------------------------------------------------

---Hides the size graph via an animation
---@param s table
---@param hideTime number
---@param callback function
function SizeGraphWidget.HideAnim(s, hideTime, callback)
    hideTime = hideTime or 0.25;

    Animation.AnimLerp(0, 1, hideTime, function (v)
        local col1 = Animation.LerpColor(0xFFFFFFFF, 0x00FFFFFF, v);
        local col2 = Animation.LerpColor(0xFF3f3f3f, 0x003f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * (1 - v);
    end)
    
    Animation.AnimLerpV2(0, 0, 500, 0, hideTime, function (x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeOutQuad");
    
    Animation.Delay(hideTime, function ()
        s.AnimData.visible = true;
        callback();
    end);
end

-------------------------------------------------------------------

function SizeGraphWidget.Draw(s, posx, posy, sizex, sizey, lineWidth, monsterSize, smallBorder, bigBorder, kingBorder)
    -- draw |---------|-o--|

    local normalizedSize = (monsterSize - smallBorder) / (kingBorder - smallBorder);
    normalizedSize = math.min(math.max(normalizedSize, 0.0), 1.0);

    local normalizedBigSize = (bigBorder - smallBorder) / (kingBorder - smallBorder);
    normalizedBigSize = math.min(math.max(normalizedBigSize, 0.0), 1.0);

    -- Draw:        90
    local sizeString = string.format("%.0f", monsterSize * 100);
    local sizeWidth, sizeHeight = Drawing.MeasureText(sizeString);

    local minString = string.format("%.0f", smallBorder * 100);
    local minWidth, minHeight = Drawing.MeasureText(sizeString);

    local maxString = string.format("%.0f", kingBorder * 100);
    local maxWidth, _ = Drawing.MeasureText(sizeString);

    local textPadMult = 2;
    local heightPadMult = 1.5;

    local scaledSizex = sizex - (minWidth * textPadMult + maxWidth * textPadMult);

    -- Draw:        100
    Drawing.DrawText(sizeString, posx + minWidth * textPadMult + scaledSizex * normalizedSize - 0.5 * sizeWidth, posy, s.AnimData.textColor);
    -- Draw: 90
    Drawing.DrawText(minString, posx, posy + heightPadMult * sizeHeight, s.AnimData.textColor);
    -- Draw: 90            123
    Drawing.DrawText(maxString, posx + sizex - maxWidth, posy + heightPadMult * sizeHeight, s.AnimData.textColor);

    local lineHeight = posy + heightPadMult * sizeHeight + 0.5 * minHeight;
    -- Draw: 90 ----------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, scaledSizex, lineWidth, s.AnimData.graphColor, 0, 0.5);
    -- Draw: 90 |---------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, lineWidth, sizey, s.AnimData.graphColor, 0.5, 0.5);
    -- Draw: 90 |---------| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex, lineHeight, lineWidth, sizey, s.AnimData.graphColor, 0.5, 0.5);
    -- Draw: 90 |------|--| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex * normalizedBigSize, lineHeight, lineWidth, sizey, s.AnimData.graphColor, 0.5, 0.5);

    -- draw crown image
    if d2d ~= nil then
        local image = nil;

        if normalizedSize >= normalizedBigSize or normalizedSize == 0 then
            if normalizedSize == 1 then
                image = Drawing.imageResources["kingCrown"];
            elseif normalizedSize >= normalizedBigSize then
                image = Drawing.imageResources["bigCrown"];
            else
                image = Drawing.imageResources["miniCrown"];
            end
        else
            image = Drawing.imageResources["monster"];
        end

        Drawing.DrawImage(image, posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, s.AnimData.iconSize, s.AnimData.iconSize, 0.5, 0.7);
    else
        draw.filled_circle(posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, s.AnimData.iconSize * 0.5, s.AnimData.graphColor, 16);
    end
end

-------------------------------------------------------------------

---Creates a new size graph
---@return table SizeGraph The newly created size graph
function SizeGraphWidget.New()
    local table = {
        AnimData = {
            textColor = 0x00FFFFFF;
            textShadowColor = 0x003f3f3f;
            graphColor = 0x00FFFFFF;
            offset = { x = 500, y = 0 },
            iconSize = 0,
            visible = false,
        },
        show = SizeGraphWidget.ShowAnim,
        hide = SizeGraphWidget.HideAnim,
        draw = SizeGraphWidget.Draw
    };

    return table;
end

-------------------------------------------------------------------
-- Init
-------------------------------------------------------------------

---Initializes the SizeGraph module
function SizeGraph.InitModule()
    -- bind game mode event
    Quests.onGameStatusChanged:add(SizeGraph.OnGameStatusChanged)

    -- bind monster add event
    Monsters.onMonsterAdded:add(function(monster)
        MonstersToAdd[#MonstersToAdd + 1] = monster;
        Utils.logDebug("onMonsterAdded: " .. monster.name);
    end);

    -- bind monster remove event
    Monsters.onMonsterRemoved:add(function(monster)
        MonstersToRemove[#MonstersToRemove + 1] = monster;
        Utils.logDebug("onMonsterRemoved: " .. monster.name);
    end);
end

return SizeGraph;