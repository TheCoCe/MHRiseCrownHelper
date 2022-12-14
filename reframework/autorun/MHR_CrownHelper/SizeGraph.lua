local SizeGraph = {};
local SizeGraphWidget = {};

local Animation  = require("MHR_CrownHelper.Animation");
local Utils      = require("MHR_CrownHelper.Utils")
local Drawing    = require("MHR_CrownHelper.Drawing")
local Monsters   = require("MHR_CrownHelper.Monsters");
local Settings   = require("MHR_CrownHelper.Settings");
local Quests     = require("MHR_CrownHelper.Quests");
local Singletons = require("MHR_CrownHelper.Singletons")

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
    Utils.logDebug("SizeGraph OnGuiTgCameraVisibilityChanged Event");
    if Quests.gameStatus == 2 then
        if vis and not TargetCamVisibleFlag then
            TargetCamVisibleFlag = true;
            if #SizeGraphMonsterList > 0 then
                SizeGraph.SizeGraphOpen();
            end
        end
    end
end

-------------------------------------------------------------------

---Game status changed callback
---@param state number
function SizeGraph.OnGameStatusChanged(state)
    Utils.logDebug("SizeGraph onGameStatusChanged Event");
    if state < 2 then
        -- reset all size graph related stuff
        TargetCamVisibleFlag = false;
        sizeGraphVisible = false;
        sizeGraphAnimating = false;
        guiTgCameraVisible = false;
        SizeGraphMonsterList = {};
        MonstersToRemove = {};
        MonstersToAdd = {};
        SizeGraphWidgets = {};
        tgCamGuiComponent = nil;
    elseif state == 2 then
        -- reset tgCamGuiComponent (no longer valid)
        tgCamGuiComponent = nil;
    end
end

-------------------------------------------------------------------

---Opens the size graph
function SizeGraph.SizeGraphOpen()
    sizeGraphVisible = true;
    sizeGraphAnimating = true;
    Utils.logDebug("sizeGraphOpening");

    local i = 1;
    local showNextItem = function(f)
        if i <= #SizeGraphMonsterList then
            local Widget = SizeGraphWidgets[SizeGraphMonsterList[i]];

            Utils.logDebug("Animating monster widget: " .. SizeGraphMonsterList[i].name);
            if not Widget.AnimData.visible then
                Utils.logDebug("widget:show ");
                Widget:show(0.5);
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

    if (Settings.current.sizeDetails.autoHideAfter > 0) then
        Animation.Delay(Settings.current.sizeDetails.autoHideAfter, function()
            SizeGraph.SizeGraphClose();
        end)
    end
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
                Widget:hide();
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

    if #MonstersToRemove > 0 then
        Utils.logDebug("Monsters to remove > 0");
        if sizeGraphVisible then
            Utils.logDebug("Size graph visible");
            if not sizeGraphAnimating then
                Utils.logDebug("Size graph not animating");
                for i = 1, #SizeGraphMonsterList, 1 do
                    if SizeGraphMonsterList[i] == MonstersToRemove[1] then
                        Utils.logDebug("Monster found index " .. i);
                        local monster = MonstersToRemove[1];
                        SizeGraphWidgets[monster]:hide(0.5, function()
                            table.remove(SizeGraphMonsterList, i);
                            SizeGraphWidgets[monster] = nil;
                        end)

                        table.remove(MonstersToRemove, 1);
                        break;
                    end
                end
            end
        else
            Utils.logDebug("Size graph not visible");
            -- remove
            for j = #MonstersToRemove, 1, -1 do
                for i = 1, #SizeGraphMonsterList, 1 do
                    if SizeGraphMonsterList[i] == MonstersToRemove[j] then
                        Utils.logDebug("Monster found index " .. i);
                        SizeGraphWidgets[SizeGraphMonsterList[i]] = nil;
                        table.remove(SizeGraphMonsterList, i);
                        table.remove(MonstersToRemove, j);
                        break;
                    end
                end
            end
        end
    end

    -- add/remove new monsters to size graph
    if TargetCamVisibleFlag then
        if #MonstersToAdd > 0 then
            Utils.logDebug("Monsters to add > 0");
            if sizeGraphVisible then
                Utils.logDebug("sizeGraphVisible == true");
                if not sizeGraphAnimating then
                    Utils.logDebug("not sizeGraphAnimating");
                    SizeGraphMonsterList[#SizeGraphMonsterList + 1] = MonstersToAdd[1];
                    table.remove(MonstersToAdd, 1);
                    local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                    SizeGraphWidgets[monster] = SizeGraphWidget.New();
                    SizeGraphWidgets[monster]:show(0.5);
                end
            else
                Utils.logDebug("sizeGraphVisible == false");
                Utils.logDebug("#SizeGraphMonsterList: " .. #SizeGraphMonsterList);
                for i = #MonstersToAdd, 1, -1 do
                    SizeGraphMonsterList[#SizeGraphMonsterList + 1] = MonstersToAdd[i];
                    Utils.logDebug("monstersToAdd remove index " .. i);
                    table.remove(MonstersToAdd, i);
                    Utils.logDebug("get monster");
                    local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                    Utils.logDebug("Create size graph widget");
                    SizeGraphWidgets[monster] = SizeGraphWidget.New();
                end
                Utils.logDebug("Open the size graph");
                SizeGraph.SizeGraphOpen();
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

local baseCtPadRight = 0.01953125; --  50
local baseCtPadTop = 0.0243056; --  35
local baseCtItemWidth = 0.0449; -- 115
local baseCtPadItem = 0.006; --  18
local baseCtPadItemBot = 0.0104167; --  15
local baseCtInfoHeight = 0.029167; --  42

---Draws a crown on top of a monster icon in the top right.
---@param monster table
---@param index number
function SizeGraph.DrawMonsterCrown(monster, index)
    -- Placing the crown and book icons
    --                     Spacing  RightOffset
    --                     ???????????????????????????????????????????????????????????????
    --          ???   ???????????????????????????????????????????????????????????????????????????????????????
    -- ctPadTop ???                              ??????
    --          ???  ??????????????????  ??????????????????  ??????????????????      ?????? TopOffset
    --             ?????????????  ?????????????  ?????????????      ??????
    --             ??????????????????  ??????????????????  ??????????????????      ??????
    --                  ????????????                   ???
    --                ctPadItem    ???????????????????????????????????????
    --                         ctItemWidth ctPadRight
    
    if (monster.isSmall or monster.isBig or monster.isKing) then
        local w, h = Drawing.GetWindowSize();
        local RightOffset = baseCtPadRight * w + baseCtItemWidth * w;
        local Spacing = baseCtItemWidth * w + baseCtPadItem * w;
        local TopOffset = baseCtPadTop * h + baseCtItemWidth * w;
        local size = baseCtItemWidth * w * 0.5;
    
        local image = monster.isKing and "kingCrown" or (monster.isBig and "bigCrown" or "miniCrown");
        
        local x, y = Drawing.FromTopRight(RightOffset + index * (Spacing + Settings.current.crownIcons.crownIconOffset.spacing), TopOffset);
        x = x + Settings.current.crownIcons.crownIconOffset.x;
        y = y + Settings.current.crownIcons.crownIconOffset.y;

        local crownSize = size * Settings.current.crownIcons.crownIconSizeMultiplier;

        Drawing.DrawImage(Drawing.imageResources[image], x, y, crownSize, crownSize, 0, 1);

        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        -- draw book icon
        if (sizeInfo and sizeInfo.crownNeeded) and Settings.current.crownIcons.showHunterRecordIcons then
            local bRightOffset = baseCtPadRight * w;

            x, y = Drawing.FromTopRight(bRightOffset + index * (Spacing + Settings.current.crownIcons.hunterRecordIconOffset.spacing), TopOffset);
            x = x + Settings.current.crownIcons.hunterRecordIconOffset.x;
            y = y + Settings.current.crownIcons.hunterRecordIconOffset.y;

            local bookSize = size * Settings.current.crownIcons.hunterRecordIconSizeMultiplier;

            Drawing.DrawImage(Drawing.imageResources["book"], x, y, bookSize, bookSize, 1, 1);
        end
    end
end

-------------------------------------------------------------------

local detailInfoSizeGraph = 100;
local detailInfoSize = 70;
local bgMarginX = 20;
local bgMarginY = 10;

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
            headerString = headerString .. crownString .. " ????";
        else
            headerString = headerString .. crownString;
        end
    end

    local w, h = Drawing.GetWindowSize();
    local posx = (baseCtPadRight * w) + 3 * (baseCtItemWidth * w) + 2 * (baseCtPadItem * w);

    local detailsHeight = Settings.current.sizeDetails.showSizeGraph and detailInfoSizeGraph or detailInfoSize;

    local posy = (baseCtPadTop * h) + (baseCtItemWidth * w) + 2 * (baseCtPadItemBot * h) + (baseCtInfoHeight * h) +
        (detailsHeight * index) + (Settings.current.sizeDetails.sizeDetailsOffset.spacing * index);

    local SizeGraphWidget = SizeGraphWidgets[monster];

    posx, posy = Drawing.FromTopRight(posx, posy);
    posx = posx + Settings.current.sizeDetails.sizeDetailsOffset.x + SizeGraphWidget.AnimData.offset.x;
    posy = posy + Settings.current.sizeDetails.sizeDetailsOffset.y + SizeGraphWidget.AnimData.offset.y;

    local sizeGraphWidth = ((3 * baseCtItemWidth * w) + (2 * baseCtPadItem * w));

    Drawing.DrawImage(Drawing.imageResources["sgbg"], posx - bgMarginX, posy - bgMarginY, sizeGraphWidth + 2 * bgMarginX
        , detailsHeight - bgMarginY, 0, 0);

    -- Draw the following:
    -- Monster name
    --                    114
    -- 90 ??????????????????????????????????????????????????????????????? 123

    Drawing.DrawText(headerString, posx, posy, SizeGraphWidget.AnimData.textColor, true, 1.5, 1.5,
        SizeGraphWidget.AnimData.textShadowColor);

    local _, height = Drawing.MeasureText(headerString);

    posy = posy + height * 1.5;
    if Settings.current.sizeDetails.showSizeGraph then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if sizeInfo ~= nil then
            SizeGraphWidget:draw(posx, posy, sizeGraphWidth, 15, 2,
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

    Animation.AnimLerp(0, 1, showTime, function(v)
        local col1 = Animation.LerpColor(0x00FFFFFF, 0xFFFFFFFF, v);
        local col2 = Animation.LerpColor(0x003f3f3f, 0xFF3f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * v;
    end)

    Animation.AnimLerpV2(500, 0, 0, 0, showTime, function(x, y)
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

    Animation.AnimLerp(0, 1, hideTime, function(v)
        local col1 = Animation.LerpColor(0xFFFFFFFF, 0x00FFFFFF, v);
        local col2 = Animation.LerpColor(0xFF3f3f3f, 0x003f3f3f, v);
        s.AnimData.textColor = col1;
        s.AnimData.textShadowColor = col2;
        s.AnimData.graphColor = col1;
        s.AnimData.iconSize = 32 * (1 - v);
    end)

    Animation.AnimLerpV2(0, 0, 500, 0, hideTime, function(x, y)
        s.AnimData.offset.x = x;
        s.AnimData.offset.y = y;
    end, "easeOutQuad");

    Animation.Delay(hideTime, function()
        s.AnimData.visible = false;
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

    local sizeString = string.format("%.0f", monsterSize * 100);
    local sizeWidth, sizeHeight = Drawing.MeasureText(sizeString);

    local minString = string.format("%.0f", smallBorder * 100);
    local minWidth, minHeight = Drawing.MeasureText(minString);

    local maxString = string.format("%.0f", kingBorder * 100);
    local maxWidth, _ = Drawing.MeasureText(maxString);

    local textPadMult = 1.5;
    local heightPadMult = 1.5;

    local scaledSizex = sizex - (minWidth * textPadMult + maxWidth * textPadMult);

    -- Draw:        100
    Drawing.DrawText(sizeString, posx + minWidth * textPadMult + scaledSizex * normalizedSize - 0.5 * sizeWidth, posy,
        s.AnimData.textColor);
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
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex, lineHeight, lineWidth, sizey, s.AnimData.graphColor,
        0.5, 0.5);
    -- Draw: 90 |------|--| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex * normalizedBigSize, lineHeight, lineWidth, sizey,
        s.AnimData.graphColor, 0.5, 0.5);

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

        Drawing.DrawImage(image, posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight,
            s.AnimData.iconSize, s.AnimData.iconSize, 0.5, 0.7);
    else
        draw.filled_circle(posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight,
            s.AnimData.iconSize * 0.5, s.AnimData.graphColor, 16);
    end
end

-------------------------------------------------------------------

---Creates a new size graph
---@return table SizeGraph The newly created size graph
function SizeGraphWidget.New()
    Utils.logDebug("new widget");
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
    Utils.logDebug("table created");

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
