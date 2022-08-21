local drawing = {};
local singletons = require("MHR_CrownHelper.singletons");
local time = require("MHR_CrownHelper.time");

-- window size
local get_main_view_method = sdk.find_type_definition("via.SceneManager"):get_method("get_MainView");
local get_window_size_method = sdk.find_type_definition("via.SceneView"):get_method("get_WindowSize");

local imgui_font;
local d2d_font;

-- image resources
local image_resource_path = "MHR_CrownHelper/";
local crown_images = {};
local book_image;


local active_anims = {};

function drawing.Init()
    if d2d ~= nil then
        crown_images[1] = d2d.Image.new(image_resource_path .. "MiniCrown.png");
        crown_images[2] = d2d.Image.new(image_resource_path .. "BigCrown.png");
        crown_images[3] = d2d.Image.new(image_resource_path .. "KingCrown.png");

        book_image = d2d.Image.new(image_resource_path .. "Book.png");

        d2d_font = d2d.Font.new("Consolas", 14, false);
    end
end

-------------------------------------------------------------------

function drawing.Update(deltaTime)
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

function drawing.draw_rect(posx, posy, sizex, sizey, color)
    if d2d ~= nil then
        d2d.fill_rect(posx, posy, sizex, sizey, color);
    else
        draw.filled_rect(posx, posy, sizex, sizey, color);
    end
end

-------------------------------------------------------------------

function drawing.argb_color_to_abgr_color(argb_color)
	local alpha = (argb_color >> 24) & 0xFF;
	local red = (argb_color >> 16) & 0xFF;
	local green = (argb_color >> 8) & 0xFF;
	local blue = argb_color & 0xFF;

	local abgr_color = 0x1000000 * alpha + 0x10000 * blue + 0x100 * green + red;

	return abgr_color;
end

-------------------------------------------------------------------

function drawing.color_to_argb(color)
	local alpha = (color >> 24) & 0xFF;
	local red = (color >> 16) & 0xFF;
	local green = (color >> 8) & 0xFF;
	local blue = color & 0xFF;

	return alpha, red, green, blue;
end

-------------------------------------------------------------------

function drawing.argb_to_color(alpha, red, green, blue)
    return 0x1000000 * alpha + 0x10000 * red + 0x100 * green + blue;
end

-------------------------------------------------------------------

function drawing.scale_color_opacity(color, scale)
	local  alpha, red, green, blue = drawing.color_to_argb(color);
	local new_alpha = math.floor(alpha * scale);
	if new_alpha < 0 then new_alpha = 0; end
	if new_alpha > 255 then new_alpha = 255; end

	return drawing.argb_to_color(new_alpha, red, green, blue);
end

-------------------------------------------------------------------

function drawing.draw_text(text, posx, posy, color, drawShadow, shadowOffsetX, shadowOffsetY, shadowColor)
    if text == nil then
        return;
    end

    if drawShadow then
        if d2d ~= nil then
            d2d.text(d2d_font, text, posx + shadowOffsetX, posy + shadowOffsetY, shadowColor);
        else
            draw.text(text, posx + shadowOffsetX, posy + shadowOffsetY, drawing.argb_color_to_abgr_color(shadowColor));
        end
    end

    if d2d ~= nil then
        d2d.text(d2d_font, text, posx, posy, color);
    else
        draw.text(text, posx, posy, drawing.argb_color_to_abgr_color(color));
    end
end

-------------------------------------------------------------------

function drawing.draw_Crown(crown, posx, posy, sizex, sizey)
    if d2d ~= nil then
        if crown_images[crown] ~= nil then
            if sizex ~= nil and sizey ~= nil then
                d2d.image(crown_images[crown], posx, posy, sizex, sizey);
            else
                d2d.image(crown_images[crown], posx, posy);
            end
        end
    end
end

-------------------------------------------------------------------

function drawing.draw_Book(posx, posy, sizex, sizey)
    if d2d ~= nil then
        if book_image ~= nil then
            if sizex ~= nil and sizey ~= nil then
                d2d.image(book_image, posx, posy, sizex, sizey);
            else
                d2d.image(book_image, posx, posy);
            end
        end
    end
end

-------------------------------------------------------------------

-- Top right camera target monster widget values
-- 50 px @ 2560x1440
local ct_padding_right = 0.01953125;
-- 35 px @ 2560x1440
local ct_padding_top = 0.0243056;
-- 115 px @ 2560x1440
local ct_item_width = 0.044921875;
-- 20 px @ 2560x1440
local ct_item_padding = 0.0078125;
-- 15 px @ 2560x1440
local ct_item_padding_bot = 0.0104167;
-- 42 px @ 2560x1440
local ct_info_height = 0.029167;

-- draws a crown ontop of a monster icon in the top right
function drawing.DrawMonsterCrown(monster, index)
    if monster.is_small or monster.is_big or monster.is_king then
        local w, h = drawing.GetWindowSize();
        
        -- crown size
        local size = (ct_item_width * w) * 0.5;
        
        -- place crowns on icon
        local posx = (ct_padding_right * w) + (index + 1) * (ct_item_width * w) + index * (ct_item_padding * w);
        local posy = (ct_padding_top * h) + (ct_item_width * w) - (size * 1.1);
        
        -- transform position
        posx, posy = drawing.FromTopRight(posx, posy);
        
        local id = 1;
        if monster.is_king then
            id = 3;
        elseif monster.is_big then
            id = 2;
        end
        
        drawing.draw_Crown(id, posx, posy, size, size);
        
        -- draw book icon
        if monster.crown_needed then
            posx = (ct_padding_right * w) + (index) * (ct_item_width * w) + index * (ct_item_padding * w) + (size * 1.1);
            -- transform position
            posx, posy = drawing.FromTopRight(posx, posy);

            drawing.draw_Book(posx, posy, size, size);
        end
    end

end

-------------------------------------------------------------------

function drawing.GetCrownThresholdString(size, small_border, big_border, king_border, steps, draw_simple)
	local crown_string = "";

	if draw_simple then
		crown_string = crown_string .. string.format("<=%.0f >=%.0f >=%.0f", 100 * small_border,
			100 * big_border, 100 * king_border);
	else
		local normalized_size = (size - small_border) / (king_border - small_border);
		normalized_size = math.min(math.max(normalized_size, 0.0), 1.0);

		local normalized_big_size = (big_border - small_border) / (king_border - small_border);
		normalized_big_size = math.min(math.max(normalized_big_size, 0.0), 1.0);

		local size_index = math.max(math.floor(normalized_size * steps), 1);
		local big_index = math.max(math.floor(normalized_big_size * steps), 1);

		crown_string = crown_string .. string.format("%.0f ", small_border * 100);

        local width = 0;
        local height = 0;

		for i = 1, steps do
			if i == size_index then
                width, height = d2d_font:measure(crown_string);
				-- king crown
                if normalized_size == 1.0 then
					crown_string = crown_string .. "👑";
					-- small crown
				elseif normalized_size == 0.0 then
					crown_string = crown_string .. "♔";
					-- big crown
				elseif normalized_size >= normalized_big_size then
					crown_string = crown_string .. "♛";
					-- no crown
				else
					crown_string = crown_string .. "⦿";
				end
			elseif i == big_index then
				crown_string = crown_string .. "┼";
			elseif i == 1 then
				crown_string = crown_string .. "├";
			elseif i == steps then
				crown_string = crown_string .. "┤";
			else
				crown_string = crown_string .. "─";
			end
		end

        local sizeString = string.format("%.0f", size * 100);
        local curWidth = d2d_font:measure(sizeString);
        local curHeight = 0;
        
        while curWidth < width do
            sizeString = "  " .. sizeString;
            curWidth, curHeight = d2d_font:measure(sizeString);
        end

		crown_string = sizeString .. "\n" .. crown_string .. string.format(" %.0f", king_border * 100);
	end

	return crown_string;
end

-------------------------------------------------------------------

local detailInfoSize = 70;
local detailPositionOffset = Vector2f.new(0, 0);

function drawing.DrawMonsterDetails(monster, index)
    local header_string = monster.name .. ": ";

    local crown_string = nil;

    if monster.is_small then
        crown_string = "Mini";
    elseif monster.is_king then
        crown_string = "Gold";
    elseif monster.is_big then
        crown_string = "Silver";
    end

    if crown_string ~= nil then
        if monster.crown_needed then
            header_string = header_string .. crown_string .. " 📙";
        else
            header_string = header_string .. "[" .. crown_string .. "]";
        end
    end

    local w, h = drawing.GetWindowSize();
    local posx = (ct_padding_right * w) + 3 * (ct_item_width * w) + 2 * (ct_item_padding * w);
    local posy = (ct_padding_top * h) + (ct_item_width * w) + 2 * (ct_item_padding_bot * h) + (ct_info_height * h) + (detailInfoSize * index);

    posx, posy = drawing.FromTopRight(posx, posy);
    posx, posy = drawing.Offset(posx, posy, detailPositionOffset);

    -- Draw the following:

    -- Monster name
    --                    114
    -- 90 ├────────────┼──♛───┤ 123

    drawing.draw_text(header_string, posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);
    posy = posy + 20;
    drawing.draw_text(drawing.GetCrownThresholdString(monster.size, monster.small_border, monster.big_border, monster.king_border, 20, false), posx, posy, 0xFFFFFFFF, true, 1.5, 1.5, 0xFF3f3f3f);
end

-------------------------------------------------------------------

function drawing.DrawMonsterDetails2(monster)
    local header_string = monster.name;

    local crown_string = nil;

    if monster.is_small then
        crown_string = "Mini";
    elseif monster.is_king then
        crown_string = "Gold";
    elseif monster.is_big then
        crown_string = "Silver";
    end

    if crown_string ~= nil then
        if monster.crown_needed then
            header_string = header_string .. ": Crown chance [" .. crown_string .. "]";
        else
            header_string = header_string .. ": [" .. crown_string .. "]";
        end
    end

    if imgui.collapsing_header(header_string) then
        imgui.text(string.format("Size: %.0f", monster.size * 100));
        imgui.push_font(imgui_font);
        imgui.text(drawing.GetCrownThresholdString(monster.size, monster.small_border, monster.big_border, monster.king_border, 20, false));
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
function drawing.BeginMonsterDetailWindow()
    local w, h = drawing.GetWindowSize();
    local pos = Vector2f.new(w - (ct_padding_right * w), window_pos.y);
    imgui.set_next_window_pos(pos, 0, window_pivot);
    local sizex = ((3 * ct_item_width) + (2 * ct_item_padding)) * w;
    imgui.set_next_window_size({sizex, window_size.y}, 0);

    return imgui.begin_window("Monster Size Details", true, 1);
end

-------------------------------------------------------------------

-- Ends the montser detail info panel
function drawing.EndMonsterDetailWindow()
    imgui.end_window();
end

-------------------------------------------------------------------

-- Gets the current window size
function drawing.GetWindowSize()
    local window_size = get_window_size_method(get_main_view_method(singletons.SceneManager));

    local w = window_size:get_field("w");
    local h = window_size:get_field("h");

    return w, h;
end

-------------------------------------------------------------------

-- transforms screen coordinates from top right 0,0
function drawing.FromTopRight(posx, posy)
    local w, h = drawing.GetWindowSize();
    return w - posx, posy;
end

-------------------------------------------------------------------

-- transforms screen coordinates from bottom right 0,0
function drawing.FromBottomRight(posx, posy)
    local w, h = drawing.GetWindowSize();
    return w - posx, h - posy;
end

-------------------------------------------------------------------

-- transforms screen coordinates from bottom left 0,0
function drawing.FromBottomLeft(posx, posy)
    local w, h = drawing.GetWindowSize();
    return posx, h - posy;
end

-------------------------------------------------------------------

-- takes x, y and Vector2f offset, returns x, y
function drawing.Offset(posx, posy, offset)
    return posx + offset.x, posy + offset.y;
end

-------------------------------------------------------------------

function drawing.InitModule()
    imgui_font = imgui.load_font("NotoSansKR-Bold.otf", imgui.get_default_font_size(), { 0x1, 0xFFFF, 0 });
end

-- TESTING --

-- todo: coroutines are not yet supported by REframework but should be part of the next release
function drawing.animated_box()
    local anim_time = 0;
    -- todo: d2d checks

    while anim_time < 5 do
        anim_time = anim_time + time.time_delta;
        log.debug(anim_time);

        local time_norm = anim_time / 5;

        local sizex = time_norm * 1000;
        local sizey = 50;

        drawing.draw_rect(500, 500, sizex, sizey, 0xFFFFFF00);

        coroutine.yield();
    end

    anim_time = 0;

    while anim_time < 3 do
        anim_time = anim_time + time.time_delta;
        log.debug(anim_time);

        local time_norm = anim_time / 3;

        local sizex = 1000;
        local sizey = 50 + time_norm * 200;

        drawing.draw_rect(500, 500, sizex, sizey, 0xFFFFFF00);

        coroutine.yield();
    end
end

function drawing.StartAnim()
    local co = coroutine.create(function ()
        print(1);
    end);

    coroutine.resume(co);

    active_anims[#active_anims+1] = co;
end

return drawing;