local Drawing = {};
local Singletons = require("MHR_CrownHelper.Singletons")
--.local Time = require("MHR_CrownHelper.Time");
local Settings = require("MHR_CrownHelper.Settings");
local Monsters = require("MHR_CrownHelper.Monsters");
local Utils    = require("MHR_CrownHelper.Utils")

-- window size
local getMainViewMethod = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local getWindowSizeMethod = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

-- aspect ratio
local getMainCamMethod = sdk.find_type_definition("snow.GameCamera"):get_method("getMainCamera");
local getAspectRatio = sdk.find_type_definition("via.Camera"):get_method("get_AspectRatio");

-- font resources
local imguiFont;
local d2dFont;

-- image resources
local imageResourcePath = "MHR_CrownHelper/";
local crownImages = {};
local bookImage;
local monsterImage;

-------------------------------------------------------------------

---Initializes the requierd resources for drawing
function Drawing.Init()
    if d2d ~= nil then
        crownImages[1] = d2d.Image.new(imageResourcePath .. "MiniCrown.png");
        crownImages[2] = d2d.Image.new(imageResourcePath .. "BigCrown.png");
        crownImages[3] = d2d.Image.new(imageResourcePath .. "KingCrown.png");

        monsterImage = d2d.Image.new(imageResourcePath .. "monster1.png");

        bookImage = d2d.Image.new(imageResourcePath .. "Book.png");

        d2dFont = d2d.Font.new("Consolas", Settings.current.text.textSize, false);
    end
end

-------------------------------------------------------------------

---Update loop (used for animation etc.)
---@param deltaTime number
function Drawing.Update(deltaTime)
    --    if d2d ~= nil then
    --        d2d.text(font, string.format("%.2f", deltaTime), 200, 200, 0xFF000000);
    --    end
    --
    --    local size = 100 * math.sin(time.time_total);
    --    drawing.draw_rect(100, 100, size, size, 0xFF000000);
    --
    --    for i = 1, #active_anims, 1 do
    --        if not coroutine.resume(active_anims[i]) then
    --            table.remove(active_anims, i);
    --        end
    --    end
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
function Drawing.DrawSizeGraph(posx, posy, sizex, sizey, lineWidth, iconSize, monsterSize, smallBorder, bigBorder, kingBorder)
    
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
    
    local scaledSizex = sizex - (minWidth  * textPadMult + maxWidth * textPadMult);

    -- Draw:        100
    Drawing.DrawText(sizeString, posx + minWidth * textPadMult + scaledSizex * normalizedSize - 0.5 * sizeWidth, posy, 0xFFFFFFFF);
    -- Draw: 90
    Drawing.DrawText(minString, posx, posy + heightPadMult * sizeHeight, 0xFFFFFFFF);
    -- Draw: 90            123
    Drawing.DrawText(maxString, posx + sizex - maxWidth, posy + heightPadMult * sizeHeight, 0xFFFFFFFF);

    local lineHeight = posy + heightPadMult * sizeHeight + 0.5 * minHeight;
    -- Draw: 90 ----------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, scaledSizex , lineWidth, 0xFFFFFFFF, 0, 0.5);
    -- Draw: 90 |---------- 123
    Drawing.DrawRect(posx + minWidth * textPadMult, lineHeight, lineWidth, sizey, 0xFFFFFFFF, 0.5, 0.5);
    -- Draw: 90 |---------| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex, lineHeight, lineWidth, sizey, 0xFFFFFFFF, 0.5, 0.5);
    -- Draw: 90 |------|--| 123
    Drawing.DrawRect(posx + minWidth * textPadMult + scaledSizex * normalizedBigSize, lineHeight, lineWidth, sizey, 0xFFFFFFFF, 0.5, 0.5);

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
        
        Drawing.DrawImage(image, posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, iconSize, iconSize, 0.5, 0.7);
    else
        draw.filled_circle(posx + minWidth * textPadMult + scaledSizex * normalizedSize, lineHeight, iconSize * 0.5, 0xFFFFFFFF, 16);
    end
end

-------------------------------------------------------------------

-- Top right camera target monster widget size values in percent derived from pixels in 2560x1440
local ctPadRight = 0.01953125;      --  50
local ctPadTop = 0.0243056;         --  35
local ctItemWidth = 0.0449;    -- 115
local ctPadItem = 0.006;        --  18
local ctPadItemBotom = 0.0104167;   --  15
local ctInfoHeight = 0.029167;      --  42

---Draws a crown on top of a monster icon in the top right.
---@param monster table
---@param index number
function Drawing.DrawMonsterCrown(monster, index)
    if monster.isSmall or monster.isBig or monster.isKing then
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
    local posy = (ctPadTop * h) + (ctItemWidth * w) + 2 * (ctPadItemBotom * h) + (ctInfoHeight * h) + (detailInfoSize * index);

    posx, posy = Drawing.FromTopRight(posx, posy);
    posx = posx + Settings.current.sizeDetails.sizeDetailsOffset.x;
    posy = posy + Settings.current.sizeDetails.sizeDetailsOffset.y;

    
    -- Draw the following:
    
    -- Monster name
    --                    114
    -- 90 ├────────────┼──♛───┤ 123
    
    Drawing.DrawText(headerString, posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);

    local _, height = d2dFont:measure(headerString);

    posy = posy + height * 1.5;
    if Settings.current.sizeDetails.showSizeGraph then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if sizeInfo ~= nil then
            Drawing.DrawSizeGraph(posx, posy, ((3 * ctItemWidth * w) + (2 * ctPadItem * w)), 15, 2, 32 , monster.size, sizeInfo.smallBorder, sizeInfo.bigBorder, sizeInfo.kingBorder);
        end
    else
        Drawing.DrawText("Size: " .. string.format("%.0f", monster.size * 100), posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);
    end
end

-------------------------------------------------------------------

---Creates a crown threshold string.
---@param size number
---@param smallBorder number
---@param bigBorder number
---@param kingBorder number
---@param steps number
---@return string sizeString The size string in the format |----⦿--|---|
function Drawing.GetCrownThresholdString(size, smallBorder, bigBorder, kingBorder, steps)
	local crownString = "";

    local normalizedSize = (size - smallBorder) / (kingBorder - smallBorder);
    normalizedSize = math.min(math.max(normalizedSize, 0.0), 1.0);

    local normalized_big_size = (bigBorder - smallBorder) / (kingBorder - smallBorder);
    normalized_big_size = math.min(math.max(normalized_big_size, 0.0), 1.0);

    local size_index = math.max(math.floor(normalizedSize * steps), 1);
    local bigIndex = math.max(math.floor(normalized_big_size * steps), 1);

    crownString = crownString .. string.format("%.0f ", smallBorder * 100);

    local sizeString = "   ";

    -- todo: replace crowns with default font icons so it can be displayed using: draw.text()

    for i = 1, steps do
        if i == size_index then
            sizeString = sizeString .. string.format("%.0f", size * 100);
            -- king crown
            if normalizedSize == 1.0 then
                crownString = crownString .. "G"; --"👑";
                -- small crown
            elseif normalizedSize == 0.0 then
                crownString = crownString .. "M"; --"♔";
                -- big crown
            elseif normalizedSize >= normalized_big_size then
                crownString = crownString .. "S"; --"♛";
                -- no crown
            else
                crownString = crownString .. "⦿";
            end
        elseif i == bigIndex then
            crownString = crownString .. "|"; -- "┼";
        elseif i == 1 then
            crownString = crownString .. "|"; --"├";
        elseif i == steps then
            crownString = crownString .. "|"; -- "┤";
        else
            crownString = crownString .. "-"; -- "─";
        end

        if i < size_index then
            sizeString = sizeString .. " ";
        end
    end

    crownString = sizeString .. "\n" .. crownString .. string.format(" %.0f", kingBorder * 100);

	return crownString;
end

-------------------------------------------------------------------

---Draws the monster details as text in an imgui window.
---@param monster table
function Drawing.DrawMonsterDetailsText(monster)
    local header_string = monster.name;

    local crown_string = nil;

    if monster.isSmall then
        crown_string = "Mini";
    elseif monster.isKing then
        crown_string = "Gold";
    elseif monster.isBig then
        crown_string = "Silver";
    end

    if crown_string ~= nil then
        local sizeInfo = Monsters.GetSizeInfoForEnemyType(monster.emType, false);
        if (sizeInfo and sizeInfo.crownNeeded) and Settings.current.sizeDetails.showHunterRecordIcons then
            header_string = header_string .. ": Crown chance [" .. crown_string .. "]";
        else
            header_string = header_string .. ": [" .. crown_string .. "]";
        end
    end

    if imgui.collapsing_header(header_string) then
        imgui.text(string.format("Size: %.0f", monster.size * 100));
        imgui.push_font(imguiFont);
        imgui.text(Drawing.GetCrownThresholdString(monster.size, monster.small_border, monster.big_border, monster.king_border, 20));
        imgui.pop_font();
        if crown_string ~= nil then
            imgui.text("Crown: " .. crown_string);
        end
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
    imguiFont = imgui.load_font("NotoSansKR-Bold.otf", Settings.current.text.textSize, { 0x1, 0xFFFF, 0 });
end

-------------------------------------------------------------------

return Drawing;
