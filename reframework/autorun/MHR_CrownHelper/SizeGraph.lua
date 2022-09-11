local SizeGraph = {};
local SizeGraphWidget = {};
local Animation = require("MHR_CrownHelper.Animation");
local Utils     = require("MHR_CrownHelper.Utils")
local Drawing   = require("MHR_CrownHelper.Drawing")

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
    Drawing.
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
    Utils.logDebug("New call");

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

return SizeGraph;