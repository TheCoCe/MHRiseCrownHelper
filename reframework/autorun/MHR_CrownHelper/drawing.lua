local drawing = {};
local time = require("MHR_CrownHelper.time");

local image_resource_path = "MHR_CrownHelper/";

local font = nil;

local crown_images = {};

local active_anims = {};

function drawing.Init()
    if d2d ~= nil then
        crown_images[1] = d2d.Image.new(image_resource_path .. "MiniCrown.png");
        crown_images[2] = d2d.Image.new(image_resource_path .. "BigCrown.png");
        crown_images[3] = d2d.Image.new(image_resource_path .. "KingCrown.png");

        font = d2d.Font.new("NotoSans", 50);
    end
end

function drawing.draw_rect(posx, posy, sizex, sizey, color)
    if d2d ~= nil then
        d2d.fill_rect(posx, posy, sizex, sizey, color);
    else
        draw.filled_rect(posx, posy, sizex, sizey, color);
    end
end

function drawing.draw_Crown(crown, posx, posy)
    if d2d ~= nil then
        if crown_images[crown] ~= nil then
            d2d.image(crown_images[crown], posx, posy);
        end

    end
end

function drawing.draw_Crown(crown, posx, posy, sizex, sizey)
    if d2d ~= nil then
        if crown_images[crown] ~= nil then
            d2d.image(crown_images[crown], posx, posy, sizex, sizey);
        end

    end
end

function drawing.Update(deltaTime)
    if d2d ~= nil then
        d2d.text(font, string.format("%.2f", deltaTime), 200, 200, 0xFF000000);
    end

    local size = 100 * math.sin(time.time_total);
    drawing.draw_rect(100, 100, size, size, 0xFF000000);

    for i = 1, #active_anims, 1 do
        if not coroutine.resume(active_anims[i]) then
            table.remove(active_anims, i);
        end
    end
end

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

function drawing.InitModule()
end

return drawing;