local Drawing = {};
local Singletons = require("MHR_CrownHelper.Singletons")
local Time = require("MHR_CrownHelper.Time");
local Settings = require("MHR_CrownHelper.Settings");

-- window size
local getMainViewMethod = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local getWindowSizeMethod = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

-- font resources
local imguiFont;
local d2dFont;

-- image resources
local imageResourcePath = "MHR_CrownHelper/";
local crownImages = {};
local bookImage;

-------------------------------------------------------------------

function Drawing.Init()
    if d2d ~= nil then
        crownImages[1] = d2d.Image.new(imageResourcePath .. "MiniCrown.png");
        crownImages[2] = d2d.Image.new(imageResourcePath .. "BigCrown.png");
        crownImages[3] = d2d.Image.new(imageResourcePath .. "KingCrown.png");

        bookImage = d2d.Image.new(imageResourcePath .. "Book.png");

        d2dFont = d2d.Font.new("Consolas", Settings.current.text.textSize, false);
    end
end

-------------------------------------------------------------------

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

function Drawing.DrawRect(posx, posy, sizex, sizey, color)
    if d2d ~= nil then
        d2d.fill_rect(posx, posy, sizex, sizey, color);
    else
        draw.filled_rect(posx, posy, sizex, sizey, color);
    end
end

-------------------------------------------------------------------

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

function Drawing.DrawImage(image, posx, posy, sizex, sizey)
    if d2d == nil or image == nil then 
        return; 
    end

    local imgWidth, imgHeight = image:size();
    sizex = sizex or imgWidth;
    sizey = sizey or imgHeight;

    d2d.image(image, posx, posy, sizex, sizey);
end

-------------------------------------------------------------------

-- Top right camera target monster widget size values in percent derived from pixels in 2560x1440
local ctPadRight = 0.01953125;      --  50
local ctPadTop = 0.0243056;         --  35
local ctItemWidth = 0.044921875;    -- 115
local ctPadItem = 0.0078125;        --  20
local ctPadItemBotom = 0.0104167;   --  15
local ctInfoHeight = 0.029167;      --  42

-- draws a crown ontop of a monster icon in the top right
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
        
        -- draw book icon
        if monster.crownNeeded and Settings.current.crownIcons.showHunterRecordIcons then
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

local detailInfoSize = 70;

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
        if monster.crownNeeded and Settings.current.sizeDetails.showHunterRecordIcons then
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

    posy = posy + 20;
    if Settings.current.sizeDetails.showSizeGraph then
        Drawing.DrawText(Drawing.GetCrownThresholdString(monster.size, monster.smallBorder, monster.bigBorder, monster.kingBorder, 20), posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);
    else
        Drawing.DrawText("Size: " .. string.format("%.0f", monster.size * 100), posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);
    end
end

-------------------------------------------------------------------

function Drawing.DrawMonsterDetails2(monster)
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
        if monster.crownNeeded then
            header_string = header_string .. ": Crown chance [" .. crown_string .. "]";
        else
            header_string = header_string .. ": [" .. crown_string .. "]";
        end
    end

    if imgui.collapsing_header(header_string) then
        imgui.text(string.format("Size: %.0f", monster.size * 100));
        imgui.push_font(imguiFont);
        imgui.text(Drawing.GetCrownThresholdString(monster.size, monster.small_border, monster.big_border, monster.king_border, 20, false));
        imgui.pop_font();
        if crown_string ~= nil then
            imgui.text("Crown: " .. crown_string);
        end
    end
end

-------------------------------------------------------------------

-- default info window size
local window_size = Vector2f.new(400, 130);
-- default window position from right
local window_pos = Vector2f.new(20, 220);
-- window pivot
local window_pivot = Vector2f.new(1, 0);

-- Creates the monster detail info window
function Drawing.BeginMonsterDetailWindow()
    local w, h = Drawing.GetWindowSize();
    local pos = Vector2f.new(w - (ctPadRight * w), window_pos.y);
    imgui.set_next_window_pos(pos, 0, window_pivot);
    local sizex = ((3 * ctItemWidth) + (2 * ctPadItem)) * w;
    imgui.set_next_window_size({sizex, window_size.y}, 0);

    return imgui.begin_window("Monster Size Details", true, 1);
end

-------------------------------------------------------------------

-- Ends the montser detail info panel
function Drawing.EndMonsterDetailWindow()
    imgui.end_window();
end

-------------------------------------------------------------------

-- Gets the current window size
function Drawing.GetWindowSize()
    local windowSize = getWindowSizeMethod(getMainViewMethod(Singletons.SceneManager));

    local w = windowSize:get_field("w");
    local h = windowSize:get_field("h");

    return w, h;
end

-------------------------------------------------------------------

-- transforms screen coordinates from top right 0,0
function Drawing.FromTopRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, posy;
end

-------------------------------------------------------------------

-- transforms screen coordinates from bottom right 0,0
function Drawing.FromBottomRight(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return w - posx, h - posy;
end

-------------------------------------------------------------------

-- transforms screen coordinates from bottom left 0,0
function Drawing.FromBottomLeft(posx, posy)
    local w, h = Drawing.GetWindowSize();
    return posx, h - posy;
end

-------------------------------------------------------------------

function Drawing.ARGBtoABGR(ARGBColor)
	local a = (ARGBColor >> 24) & 0xFF;
	local r = (ARGBColor >> 16) & 0xFF;
	local g = (ARGBColor >> 8) & 0xFF;
	local b = ARGBColor & 0xFF;

	local ABGRColor = 0x1000000 * a + 0x10000 * b + 0x100 * g + r;

	return ABGRColor;
end

-------------------------------------------------------------------

function Drawing.InitModule()
    imguiFont = imgui.load_font("NotoSansKR-Bold.otf", Settings.current.text.textSize, { 0x1, 0xFFFF, 0 });
end

-------------------------------------------------------------------

return Drawing;

--[[
     local active_anims = {};

    -- todo: coroutines are not yet supported by REframework but should be part of the next release
    function Drawing.AnimatedBox()
        local anim_time = 0;
        -- todo: d2d checks
        
        while anim_time < 5 do
            anim_time = anim_time + Time.timeDelta;
            log.debug(anim_time);
            
            local time_norm = anim_time / 5;
            
            local sizex = time_norm * 1000;
            local sizey = 50;
            
            Drawing.DrawRect(500, 500, sizex, sizey, 0xFFFFFF00);
            
            coroutine.yield();
        end
        
        anim_time = 0;
        
        while anim_time < 3 do
            anim_time = anim_time + Time.timeDelta;
            log.debug(anim_time);
            
            local time_norm = anim_time / 3;
            
            local sizex = 1000;
            local sizey = 50 + time_norm * 200;
            
            Drawing.DrawRect(500, 500, sizex, sizey, 0xFFFFFF00);
            
            coroutine.yield();
        end
    end
    
    function Drawing.StartAnim()
        local co = coroutine.create(function ()
            print(1);
        end);

    coroutine.resume(co);
    
    active_anims[#active_anims+1] = co;
end
]]
