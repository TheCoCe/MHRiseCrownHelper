local SettingsMenu = {};

local Settings      = require("MHR_CrownHelper.Settings");
local CrownTracker  = require("MHR_CrownHelper.CrownTracker");
local Notifications = require("MHR_CrownHelper.Notifications")

SettingsMenu.windowPosition = Vector2f.new(400, 200);
SettingsMenu.windowPivot = Vector2f.new(0, 0);
SettingsMenu.windowSize = Vector2f.new(400, 400);
SettingsMenu.windowFlags = 0x10120;

SettingsMenu.isOpened = false;

-------------------------------------------------------------------

---Draws the settings menu in a imgui window
function SettingsMenu.Draw()
    imgui.set_next_window_pos(SettingsMenu.windowPosition, 1 << 3, SettingsMenu.windowPivot);
    imgui.set_next_window_size(SettingsMenu.windowSize, 1 << 3);

    SettingsMenu.isOpened = imgui.begin_window("MHR CrownHelper Settings", SettingsMenu.isOpened, SettingsMenu.windowFlags);

    if not SettingsMenu.isOpened then
        return;
    end

    local settingsChanged = false;
    local changed = false;

    if imgui.tree_node("Crown Icons") then
        changed, Settings.current.crownIcons.showCrownIcons = imgui.checkbox("Show crown icons", Settings.current.crownIcons.showCrownIcons);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownIcons.crownIconSizeMultiplier = imgui.drag_float("Crown Icon Size", Settings.current.crownIcons.crownIconSizeMultiplier, 0.1, 0, 10, "%.1f");
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownIcons.crownIconOffset.spacing = imgui.drag_float("Crown Icon Spacing", Settings.current.crownIcons.crownIconOffset.spacing, 0.1, 0, 0, "%.1f");
        settingsChanged = settingsChanged or changed;

        local CrownIconOffset = Vector2f.new(Settings.current.crownIcons.crownIconOffset.x, Settings.current.crownIcons.crownIconOffset.y);
        changed, CrownIconOffset = imgui.drag_float2("Crown Icon Offset", CrownIconOffset, 1, 0, 0, "%.1f");
        if changed then
            Settings.current.crownIcons.crownIconOffset.x = CrownIconOffset.x;
            Settings.current.crownIcons.crownIconOffset.y = CrownIconOffset.y;
        end
        settingsChanged = settingsChanged or changed;
        
        imgui.new_line();

        changed, Settings.current.crownIcons.showHunterRecordIcons = imgui.checkbox("Show hunter record icons", Settings.current.crownIcons.showHunterRecordIcons);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownIcons.hunterRecordIconSizeMultiplier = imgui.drag_float("Hunter Record Icon Size", Settings.current.crownIcons.hunterRecordIconSizeMultiplier, 0.1, 0, 10, "%.1f");
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownIcons.hunterRecordIconOffset.spacing = imgui.drag_float("Book Icon Spacing", Settings.current.crownIcons.hunterRecordIconOffset.spacing, 0.1, 0, 0, "%.1f");
        settingsChanged = settingsChanged or changed;

        local HunterRecordIconOffset = Vector2f.new(Settings.current.crownIcons.hunterRecordIconOffset.x, Settings.current.crownIcons.hunterRecordIconOffset.y);
        changed, HunterRecordIconOffset = imgui.drag_float2("Hunter Record Icon Offset", HunterRecordIconOffset, 1, 0, 0, "%.1f");
        if changed then
            Settings.current.crownIcons.hunterRecordIconOffset.x = HunterRecordIconOffset.x;
            Settings.current.crownIcons.hunterRecordIconOffset.y = HunterRecordIconOffset.y;
        end
        settingsChanged = settingsChanged or changed;

        imgui.new_line();
        imgui.tree_pop();
    end

    if imgui.tree_node("Size Details") then
        changed, Settings.current.sizeDetails.showSizeDetails = imgui.checkbox("Show size details", Settings.current.sizeDetails.showSizeDetails);
        settingsChanged = settingsChanged or changed;

        imgui.new_line();

        changed, Settings.current.sizeDetails.showHunterRecordIcons = imgui.checkbox("Show hunter record icons", Settings.current.sizeDetails.showHunterRecordIcons);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.sizeDetails.showSizeGraph = imgui.checkbox("Draw size graph", Settings.current.sizeDetails.showSizeGraph);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.sizeDetails.autoHideAfter = imgui.drag_float("Auto hide seconds", Settings.current.sizeDetails.autoHideAfter, 0.1, 0, 3600, "%.1f");
        settingsChanged = settingsChanged or changed;

        imgui.new_line();

        local SizeDetailsOffset = Vector2f.new(Settings.current.sizeDetails.sizeDetailsOffset.x, Settings.current.sizeDetails.sizeDetailsOffset.y);
        changed, SizeDetailsOffset = imgui.drag_float2("Size Details Offset", SizeDetailsOffset, 1, 0, 0, "%.1f");
        if changed then
            Settings.current.sizeDetails.sizeDetailsOffset.x = SizeDetailsOffset.x;
            Settings.current.sizeDetails.sizeDetailsOffset.y = SizeDetailsOffset.y;
        end
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.sizeDetails.sizeDetailsOffset.spacing = imgui.drag_float("Size Details Spacing", Settings.current.sizeDetails.sizeDetailsOffset.spacing, 0.1, 0, 0, "%.1f");
        settingsChanged = settingsChanged or changed;

        imgui.tree_pop();
    end

    if imgui.tree_node("Crown notifications") then
        changed, Settings.current.notifications.showNotifications = imgui.checkbox("Show notifications", Settings.current.notifications.showNotifications);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.notifications.ignoreSilverCrowns = imgui.checkbox("Ignore silver crowns", Settings.current.notifications.ignoreSilverCrowns);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.notifications.ignoreObtainedCrowns = imgui.checkbox("Ignore obtained crowns", Settings.current.notifications.ignoreObtainedCrowns);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.notifications.notificionDisplayTime = imgui.drag_float("Display time", Settings.current.notifications.notificionDisplayTime, 0.1, 0, 60, "%.1f");
        settingsChanged = settingsChanged or changed;

        local notificationsOffset = Vector2f.new(Settings.current.notifications.notificationsOffset.x, Settings.current.notifications.notificationsOffset.y);
        changed, notificationsOffset = imgui.drag_float2("Offset", notificationsOffset, 1, 0, 0, "%.1f");
        if changed then
            Settings.current.notifications.notificationsOffset.x = notificationsOffset.x;
            Settings.current.notifications.notificationsOffset.y = notificationsOffset.y;
        end
        settingsChanged = settingsChanged or changed;

        if imgui.button("Show test notification") then
            Notifications.AddNotification("Test");
        end

        imgui.tree_pop();
    end

    if imgui.tree_node("Crown Tracker") then
        if not CrownTracker.crownTableVisible and Settings.current.crownTracker.showCrownTracker then
            if imgui.button("Open Crown Tracker") then
                CrownTracker.crownTableVisible = true;
            end
        end

        changed, Settings.current.crownTracker.showCrownTracker = imgui.checkbox("Show crown tracker", Settings.current.crownTracker.showCrownTracker);
        settingsChanged = settingsChanged or changed;

        imgui.new_line();

        changed, Settings.current.crownTracker.hideComplete = imgui.checkbox("Hide completed monsters", Settings.current.crownTracker.hideComplete);
        settingsChanged = settingsChanged or changed;

        changed, Settings.current.crownTracker.showCurrentRecords = imgui.checkbox("Show current records", Settings.current.crownTracker.showCurrentRecords);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownTracker.showSizeBorders = imgui.checkbox("Show size borders", Settings.current.crownTracker.showSizeBorders);
        settingsChanged = settingsChanged or changed;

        imgui.new_line();

        if imgui.button("Reset window position/size") then
            CrownTracker.ResetWindow();
        end

        imgui.tree_pop();
    end

    imgui.end_window();

    if settingsChanged then
        Settings.Save();
    end
end 

-------------------------------------------------------------------

return SettingsMenu;