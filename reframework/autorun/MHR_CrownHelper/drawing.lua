local Drawing    = {};
local Singletons = require("MHR_CrownHelper.Singletons")
local Settings   = require("MHR_CrownHelper.Settings");
local Monsters   = require("MHR_CrownHelper.Monsters");
local Utils      = require("MHR_CrownHelper.Utils")
local Animation  = require("MHR_CrownHelper.Animation")
local Quests     = require("MHR_CrownHelper.Quests")
local SizeGraph  = require("MHR_CrownHelper.SizeGraph")

-- window size
local getMainViewMethod = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local getWindowSizeMethod = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

-- aspect ratio
local getMainCamMethod = sdk.find_type_definition("snow.GameCamera"):get_method("getMainCamera");
local getAspectRatio = sdk.find_type_definition("via.Camera"):get_method("get_AspectRatio");

-- font resources
--local imguiFont;
local d2dFont;

-- image resources
Drawing.imageResourcePath = "MHR_CrownHelper/";
Drawing.imageResources = {};
local bookImage;

-- tgCamera gui visibility
local getTgCameraHudMethod = sdk.find_type_definition("snow.gui.GuiManager"):get_method("get_refGuiHud_TgCamera");
local getTgCameraHudComponentMethod = sdk.find_type_definition("via.gui.PlayObject"):get_method("get_Component");
local getTgCameraHudEnabled = sdk.find_type_definition("via.gui.GUI"):get_method("get_Enabled");
local tgCamGuiComponent;
local guiTgCameraVisible = false;

-- runtime
local TargetCamVisibleFlag = false;
local sizeGraphVisible = false;
local sizeGraphAnimating = false;

-- local namespaces
local Callbacks = {};
local Anims = {};

local SizeGraphMonsterList = {};
local SizeGraphWidgets = {};
local monstersToRemove = {};
local monstersToAdd = {};

------------------------- Events ----------------------------------

function Callbacks.OnGuiTgCameraVisibilityChanged(vis)
    if Quests.gameStatus == 2 then
        if vis and not TargetCamVisibleFlag then
            TargetCamVisibleFlag = true;
            Anims.SizeGraphOpen();
        end
    end
end

function Callbacks.OnGameStatusChanged(state)
    if state < 2 then
        TargetCamVisibleFlag = false;
        SizeGraphMonsterList = {};
        monstersToRemove = {};
        monstersToAdd = {};
    elseif state == 2 then
        -- reset tgCamGuiComponent (no longer valid)
        tgCamGuiComponent = nil;
        -- start delay for size details auto hide
        if Settings.current.sizeDetails.autoHideAfter > 0 then
            Animation.Delay(Settings.current.sizeDetails.autoHideAfter, function()
                Anims.SizeGraphClose();
            end)
        end
    end
end

------------------------- Anims ----------------------------------

function Anims.SizeGraphOpen()
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

function Anims.SizeGraphClose()
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

---Initializes the requierd resources for drawing
function Drawing.Init()
    if d2d ~= nil then
        Drawing.InitImage("miniCrown", "MiniCrown.png");
        Drawing.InitImage("bigCrown", "BigCrown.png");
        Drawing.InitImage("kingCrown", "KingCrown.png");

        Drawing.InitImage("monster", "monster1.png");
        --monsterImage = d2d.Image.new(Drawing.imageResourcePath .. "monster1.png");

        bookImage = d2d.Image.new(Drawing.imageResourcePath .. "Book.png");

        d2dFont = d2d.Font.new("Consolas", Settings.current.text.textSize, false);
    end
end

-------------------------------------------------------------------

---Initializes a image resource from the given image name to be retrieved later using the given key.
---The image directroy will automatically be prepended to the image path.
---@param key string
---@param image string
function Drawing.InitImage(key, image)
    if d2d ~= nil then
        Drawing.imageResources[key] = d2d.Image.new(Drawing.imageResourcePath .. image);
    end
end

-------------------------------------------------------------------

---Update loop (used for animation/ui updates etc.)
---@param deltaTime number
function Drawing.Update(deltaTime)
    Animation.Update(deltaTime);

    -- handle new monsters
    -- FIXME: Monsters are often removed and added in the same timeframe
    -- this causes the hide animation to play for anim index 3  and then show for index 4
    -- while index 4 is showing index 3 is removed which causes index 4 (still in show)
    -- to jump to index 3 and thus be hidden as 3 was hidden
    -- either lock indices while animating or save a monster to anim data map instead of hard indices
    if TargetCamVisibleFlag then
        if #monstersToAdd > 0 then
            if sizeGraphVisible then
                if not sizeGraphAnimating then
                    SizeGraphMonsterList[#SizeGraphMonsterList + 1] = monstersToAdd[1];
                    table.remove(monstersToAdd, 1);
                    local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                    SizeGraphWidgets[monster] = SizeGraph.New();
                    SizeGraphWidgets[monster]:show(5);
                end
            else
                SizeGraphMonsterList[#SizeGraphMonsterList + 1] = monstersToAdd[1];
                table.remove(monstersToAdd, 1);
                local monster = SizeGraphMonsterList[#SizeGraphMonsterList];
                SizeGraphWidgets[monster] = SizeGraph.New();

                Anims.SizeGraphOpen();
            end
        end

        if #monstersToRemove > 0 then
            Utils.logDebug("Monsters to remove > 0");
            if sizeGraphVisible then
                Utils.logDebug("SizeGraphVisible = true");
                if not sizeGraphAnimating then
                    Utils.logDebug("sizeGraph is not animating");
                    for i = 1, #SizeGraphMonsterList, 1 do
                        if SizeGraphMonsterList[i] == monstersToRemove[1] then
                            Utils.logDebug("Found monster to remove");
                            local monster = monstersToRemove[1];
                            SizeGraphWidgets[monster]:hide(5, function()
                                Utils.logDebug("Remove from sizeGraphMonsterList");
                                table.remove(SizeGraphMonsterList, i);
                                SizeGraphWidgets[monster] = nil;
                            end)

                            table.remove(monstersToRemove, 1);
                            break;
                        end
                    end
                end
            else
                -- remove
                for i = 1, #SizeGraphMonsterList, 1 do
                    if SizeGraphMonsterList[i] == monstersToRemove[1] then
                        table.remove(SizeGraphMonsterList, i);
                        table.remove(monstersToRemove, i);
                        break;
                    end
                end
            end
        end
    end

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
            Callbacks.OnGuiTgCameraVisibilityChanged(guiTgCameraVisible);
        end
    end

    -- draw in quest infos
    if Quests.gameStatus == 2 then
        -- iterate over all monsters and call DrawMonsterCrown for each one
        if Settings.current.crownIcons.showCrownIcons then
            if guiTgCameraVisible then
                Monsters.IterateMonsters(Drawing.DrawMonsterCrown);
            end
        end
        if Settings.current.sizeDetails.showSizeDetails then
            if guiTgCameraVisible then
                -- Monsters.IterateMonsters(Drawing.DrawMonsterDetails);
                for i = 1, #SizeGraphMonsterList, 1 do
                    Drawing.DrawMonsterDetails(SizeGraphMonsterList[i], i - 1);
                end
            end
        end
    end
end

-------------------------------------------------------------------

---Draws a circle at the specified position. Only call this from re.on_frame or re.on_draw_ui!
---@param posx number The x center position.
---@param posy number The y center position.
---@param radius number The circles radius.
---@param color number As hex e.g. 0xFFFFFFFF.
function Drawing.DrawCircle(posx, posy, radius, color)
    draw.filled_circle(posx, posy, radius, color, 16);
end

-------------------------------------------------------------------

---Draws a rectangle at the specified location with the specified size
---@param posx number
---@param posy number
---@param sizex number
---@param sizey number
---@param color number
---@param pivotx number
---@param pivoty number
function Drawing.DrawRect(posx, posy, sizex, sizey, color, pivotx, pivoty)
    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

    if d2d ~= nil then
        d2d.fill_rect(posx - sizex * pivotx, posy - sizey * pivoty, sizex, sizey, color);
    else
        draw.filled_rect(posx - sizex * pivotx, posy - sizey * pivoty, sizex, sizey, color);
    end
end

-------------------------------------------------------------------

---Draws a text at the specified location with optional text shadow
---@param text string
---@param posx number
---@param posy number
---@param color number
---@param drawShadow boolean|nil
---@param shadowOffsetX number|nil
---@param shadowOffsetY number|nil
---@param shadowColor integer|nil
function Drawing.DrawText(text, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor)
    if text == nil then
        return;
    end

    if drawShadow then
        if d2d ~= nil then
            d2d.text(d2dFont, text, posx + shadowOffsetX, posy + shadowOffsetY, shadowColor);
        else
            draw.text(text, posx + shadowOffsetX, posy + shadowOffsetY, Drawing.ARGBtoABGR(shadowColor));
        end
    end

    if d2d ~= nil then
        d2d.text(d2dFont, text, posx, posy, color);
    else
        draw.text(text, posx, posy, Drawing.ARGBtoABGR(color));
    end
end

-------------------------------------------------------------------

---Measures the text in the current drawing font
---@param text string
---@return number
function Drawing.MeasureText(text)
    if d2dFont then
        return d2dFont:measure(text);
    end

    return 0;
end

-------------------------------------------------------------------

---Draws an image at the specified location with optional size and pivot
---@param image any
---@param posx number
---@param posy number
---@param sizex number|nil
---@param sizey number|nil
---@param pivotx number|nil
---@param pivoty number|nil
function Drawing.DrawImage(image, posx, posy, sizex, sizey, pivotx, pivoty)
    if d2d == nil or image == nil then
        return;
    end

    pivotx = pivotx or 0;
    pivoty = pivoty or 0;

    local imgWidth, imgHeight = image:size();
    sizex = sizex or imgWidth;
    sizey = sizey or imgHeight;

    posx = posx - pivotx * sizex;
    posy = posy - pivoty * sizey

    d2d.image(image, posx, posy, sizex, sizey);
end

-------------------------------------------------------------------

---Draws a size graph for the provided size infos
---@param posx number
---@param posy number
---@param sizex number
---@param sizey number
---@param lineWidth number
---@param iconSize number
---@param monsterSize number
---@param smallBorder number
---@param bigBorder number
---@param kingBorder number
---@param color? number
function Drawing.DrawSizeGraph(posx, posy, sizex, sizey, lineWidth, iconSize, monsterSize, smallBorder, bigBorder,
                               kingBorder, color)
    color = color or 0xFFFFFFFF;
    -- draw |---------|-o--|

    local normalizedSize = (monsterSize - smallBorder) / (kingBorder - smallBorder);
    normalizedSize = math.min(math.max(normalizedSize, 0.0), 1.0);

    local normalizedBigSize = (bigBorder - smallBorder) / (kingBorder - smallBorder);
    normalizedBigSize = math.min(math.max(normalizedBigSize, 0.0), 1.0);

    -- Draw:        90

    local sizeString = string.format("%.0f", monsterSize * 100);
    local sizeWidth, sizeHeight = d2dFont:measure(sizeString);

    local minString = string.format("%.0f", smallBorder * 100);
    local minWidth, minHeight = d2dFont:measure(minString);

    local maxString = string.format("%.0f", kingBorder * 100);
    local maxWidth, _ = d2dFont:measure(maxString);

    local textPadMult = 2;
    local heightPadMult = 1.5;

    local scaledSizex = sizex - (minWidth * textPadMult + maxWidth * textPadMult);

    -- Draw:        100
    Drawing.DrawText(sizeString, posx + minWidth * textPadMult + scaledSizex * normalizedSize - 0.5 * sizeWidth, posy,
        color);
    -- Draw: 90
    Drawing.DrawText(minString, posx, posy + heightPadMult * sizeHeight, color);
    -- Draw: 90            123
    Drawing.DrawText(maxString, posx + sizex - maxWidth, posy + heightPadMult * sizeHeight, color);

    local lineHeight = posy + heightPadMult * sizeHeight + 0.5 * minHeight;
    -- Draw: 90 ----------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, scaledSizex, lineWidth, color, 0, 0.5);
    -- Draw: 90 |---------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, lineWidth, sizey, color, 0.5, 0.5);
    -- Draw: 90 |---------| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex, lineHeight, lineWidth, sizey, color, 0.5, 0.5);
    -- Draw: 90 |------|--| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex * normalizedBigSize, lineHeight, lineWidth, sizey,
        color, 0.5, 0.5);

    -- draw crown image
    if d2d ~= nil then
        local image = nil;

        if normalizedSize >= normalizedBigSize or normalizedSize == 0 then
            if normalizedSize == 1 then
                image = crownImages[3];
            elseif normalizedSize >= normalizedBigSize then
                image = crownImages[2];
            else
                image = crownImages[1];
            end
        else
            image = monsterImage;
        end

        Drawing.DrawImage(image, posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, iconSize,
            iconSize, 0.5, 0.7);
    else
        draw.filled_circle(posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, iconSize * 0.5,
            color, 16);
    end
end

-------------------------------------------------------------------

-- Top right camera target monster widget size values in percent derived from pixels in 2560x1440
local ctPadRight = 0.01953125; --  50
local ctPadTop = 0.0243056; --  35
local ctItemWidth = 0.0449; -- 115
local ctPadItem = 0.006; --  18
local ctPadItemBotom = 0.0104167; --  15
local ctInfoHeight = 0.029167; --  42

---Draws a crown on top of a monster icon in the top right.
---@param monster table
---@param index number
function Drawing.DrawMonsterCrown(monster, index)
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

        local id = 1;
        if monster.isKing then
            id = 3;
        elseif monster.isBig then
            id = 2;
        end

        Drawing.DrawImage(crownImages[id], posx, posy, size, size);

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

            Drawing.DrawImage(bookImage, posx, posy, size, size);
        end
    end

end

-------------------------------------------------------------------

local detailInfoSize = 80;

---Draws monster size details.
---@param monster table
---@param index number
function Drawing.DrawMonsterDetails(monster, index)
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

    local _, height = d2dFont:measure(headerString);

    posy = posy + height * 1.5;
    if Settings.current.sizeDetails.showSizeGraph then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if sizeInfo ~= nil then
            SizeGraphWidget:draw(posx, posy, ((3 * ctItemWidth * w) + (2 * ctPadItem * w)), 15, 2, 
                monster.size, sizeInfo.smallBorder, sizeInfo.bigBorder, sizeInfo.kingBorder);
            --[[
                Drawing.DrawSizeGraph(posx, posy, ((3 * ctItemWidth * w) + (2 * ctPadItem * w)), 15, 2,
                SizeGraphWidget.AnimData.iconSize, monster.size,
                sizeInfo.smallBorder, sizeInfo.bigBorder, sizeInfo.kingBorder, SizeGraphWidget.AnimData.graphColor);
            ]]
        end
    else
        Drawing.DrawText("Size: " .. string.format("%.0f", monster.size * 100), posx, posy,
            SizeGraphWidget.AnimData.textColor, true, 1.5, 1.5,
            SizeGraphWidget.AnimData.textShadowColor);
    end
end

-------------------------------------------------------------------

---Gets the current window size
---@return number width Width of the window
---@return number height Height of the window
function Drawing.GetWindowSize()
    local windowSize = getWindowSizeMethod(getMainViewMethod(Singletons.SceneManager));

    local w = windowSize.w;
    local h = windowSize.h;

    return w, h;
end

-------------------------------------------------------------------

---Gets the current aspect ratio
---@return number aspectRatio
function Drawing.GetAspectRatio()
    local cam = getMainCamMethod(Singletons.GameCamera);
    if cam ~= nil then
        return getAspectRatio(cam);
    end

    return 1;
end

-------------------------------------------------------------------

---Converts the location for top left to top right
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromTopRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, posy;
end

-------------------------------------------------------------------

---Converts the location for top left to bottom right
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromBottomRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, h - posy;
end

-------------------------------------------------------------------

---Converts the location for top left to bottom left
---@param posx number
---@param posy number
---@return number posx
---@return number posy
function Drawing.FromBottomLeft(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return posx, h - posy;
end

-------------------------------------------------------------------

---Conerts a color from ARGB to ABGR: 0x00112233 -> 0x00332211
---@param ARGBColor integer|nil
---@return integer ABGRColor The color in the format ABGR
function Drawing.ARGBtoABGR(ARGBColor)
    local a = (ARGBColor >> 24) & 0xFF;
    local r = (ARGBColor >> 16) & 0xFF;
    local g = (ARGBColor >> 8) & 0xFF;
    local b = ARGBColor & 0xFF;

    local ABGRColor = 0x1000000 * a + 0x10000 * b + 0x100 * g + r;

    return ABGRColor;
end

-------------------------------------------------------------------

---Initializes the Drawing module
function Drawing.InitModule()
    --imguiFont = imgui.load_font("NotoSansKR-Bold.otf", Settings.current.text.textSize, { 0x1, 0xFFFF, 0 });
    Drawing.Init();

    -- bind game mode event
    Quests.onGameStatusChanged:add(Callbacks.OnGameStatusChanged)

    -- bind monster add event
    Monsters.onMonsterAdded:add(function(monster)
        monstersToAdd[#monstersToAdd + 1] = monster;
    end);

    -- bind monster remove event
    Monsters.onMonsterRemoved:add(function(monster)
        monstersToRemove[#monstersToRemove + 1] = monster;
    end);
end

-------------------------------------------------------------------

return Drawing;
