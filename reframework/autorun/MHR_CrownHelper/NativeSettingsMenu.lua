local NativeSettingsMenu = {};
local OptionsMenu;
local Settings = require("MHR_CrownHelper.Settings");
local Utils    = require("MHR_CrownHelper.Utils");
local CrownTracker = require("MHR_CrownHelper.CrownTracker")

local ModMenu;
local ShowCrownIconAdvanced = false;
local ShowSizeAdvanced = false;
local ShowString = "Show";
local HideString = "Hide";

NativeSettingsMenu.Initialized = false;

--no idea how this works but google to the rescue
--can use this to check if the api is available and do an alternative to avoid complaints from users
function NativeSettingsMenu.IsModuleAvailable(name)
  if package.loaded[name] then
    return true
  else
---@diagnostic disable-next-line: deprecated
    for _, searcher in ipairs(package.searchers or package.loaders) do
      local loader = searcher(name)
      if type(loader) == 'function' then
        package.preload[name] = loader
        return true
      end
    end
    return false
  end
end

--[[
	Here's a List of all the available api functions:
	all tooltip type things should be optional
	
	ModUI.OnMenu(name, descript, uiCallback)
	ModUI.FloatSlider(label, curValue, min, max, toolTip, isImmediateUpdate) -- keep in mind this value only has precision to the nearest hundreth
	ModUI.Slider(label, curValue, min, max, toolTip, isImmediateUpdate)
	ModUI.Button(label, prompt, isHighlight, toolTip)
	ModUI.CheckBox(label, curValue, toolTip)
	ModUI.Toggle(label, curValue, toolTip, (optional)togNames[2], (optional)togMsgs[2], isImmediateUpdate)
	ModUI.Label(label, displayValue, toolTip)
	ModUI.Options(label, curValue, optionNames, optionMessages, toolTip, isImmediateUpdate)
	ModUI.PromptYN(promptMessage, callback(result))
	ModUI.PromptMsg(promptMessage, callback)
	
	ModUI.Repaint() -- forces game to re-show the data and show changes
	ModUI.ForceDeselect() -- forces game to deselect current option
	modObj.regenOptions -- can be set to true to force the API to regenerate the UI layout, but you probably dont need this
	
	--call this BEFORE your UI code
	--keep in mind these are shared across mods so use descriptive names
	--do NOT include # in your hex color code string
	ModUI.AddTextColor(colName, colHexStr)
	
	ModUI.IncreaseIndent()
	ModUI.DecreaseIndent()
	ModUI.SetIndent(indentLevel)
]]--

function NativeSettingsMenu.Init()
    if not OptionsMenu then return; end
    ModMenu = OptionsMenu.OnMenu("MHR Crown Helper", "Description", NativeSettingsMenu.DrawMenu);
    Utils.logDebug("NativeSettingsMenu Init");
end

-------------------------------------------------------------------

function NativeSettingsMenu.DrawMenu()
    local settingsChanged = false;
    local changed = false;

    -------------------- Crown Icons --------------------

    OptionsMenu.Header("Crown/Record Icons");

    changed, Settings.current.crownIcons.showCrownIcons = OptionsMenu.CheckBox("Show crown icons", Settings.current.crownIcons.showCrownIcons);
    settingsChanged = settingsChanged or changed;
    
    changed, Settings.current.crownIcons.showHunterRecordIcons = OptionsMenu.CheckBox("Show record icon", Settings.current.crownIcons.showHunterRecordIcons);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.crownIcons.hunterRecordIconSizeMultiplier = OptionsMenu.FloatSlider("Hunter Record Icon Size", Settings.current.crownIcons.hunterRecordIconSizeMultiplier, 0, 10);
    settingsChanged = settingsChanged or changed;

    if OptionsMenu.Button("Advanced Crown Settings", (ShowCrownIconAdvanced and HideString or ShowString)) then
        ShowCrownIconAdvanced = not ShowCrownIconAdvanced;
    end

    -------------------- Crown Icons Advanced --------------------

    if ShowCrownIconAdvanced then
        OptionsMenu.IncreaseIndent();
        OptionsMenu.Label("Crown Icons:");
        OptionsMenu.IncreaseIndent();
        
        changed, Settings.current.crownIcons.crownIconSizeMultiplier = OptionsMenu.FloatSlider("Crown Icon Size", Settings.current.crownIcons.crownIconSizeMultiplier, 0, 10);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownIcons.crownIconOffset.x = OptionsMenu.Slider("Crown Icon X Offset", Settings.current.crownIcons.crownIconOffset.x, -1000, 1000);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownIcons.crownIconOffset.y = OptionsMenu.Slider("Crown Icon Y Offset", Settings.current.crownIcons.crownIconOffset.y, -1000, 1000);
        settingsChanged = settingsChanged or changed;

        OptionsMenu.DecreaseIndent();
        OptionsMenu.Label("Record Icons:");
        OptionsMenu.IncreaseIndent();
        
        changed, Settings.current.crownIcons.hunterRecordIconSizeMultiplier = OptionsMenu.FloatSlider("Record Icon Size", Settings.current.crownIcons.hunterRecordIconSizeMultiplier, 0, 10);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownIcons.hunterRecordIconOffset.x = OptionsMenu.Slider("Record Icon X Offset", Settings.current.crownIcons.hunterRecordIconOffset.x, -1000, 1000);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownIcons.hunterRecordIconOffset.y = OptionsMenu.Slider("Record Icon Y Offset", Settings.current.crownIcons.hunterRecordIconOffset.y, -1000, 1000);
        settingsChanged = settingsChanged or changed;
        
        OptionsMenu.DecreaseIndent();
        OptionsMenu.DecreaseIndent();
    end
    
    -------------------- Size Details --------------------

    OptionsMenu.Header("Size Details");

    changed, Settings.current.sizeDetails.showSizeDetails = OptionsMenu.CheckBox("Show size details", Settings.current.sizeDetails.showSizeDetails);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.sizeDetails.showHunterRecordIcons = OptionsMenu.CheckBox("Show hunter record icon", Settings.current.sizeDetails.showHunterRecordIcons);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.sizeDetails.showSizeGraph = OptionsMenu.CheckBox("Draw size graph", Settings.current.sizeDetails.showSizeGraph);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.sizeDetails.autoHideAfter = OptionsMenu.Slider("Auto hide after", Settings.current.sizeDetails.autoHideAfter, 0, 240);
    settingsChanged = settingsChanged or changed;

    if OptionsMenu.Button("Advanced Crown Settings", (ShowSizeAdvanced and HideString or ShowString)) then
        ShowSizeAdvanced = not ShowSizeAdvanced;
    end

    -------------------- Size Details Advanced --------------------

    if ShowSizeAdvanced then
        OptionsMenu.IncreaseIndent();

        changed, Settings.current.crownIcons.hunterRecordIconOffset.x = OptionsMenu.Slider("Size Details X Offset", Settings.current.crownIcons.hunterRecordIconOffset.x, -1000, 1000);
        settingsChanged = settingsChanged or changed;
        
        changed, Settings.current.crownIcons.hunterRecordIconOffset.y = OptionsMenu.Slider("Size Details Y Offset", Settings.current.crownIcons.hunterRecordIconOffset.y, -1000, 1000);
        settingsChanged = settingsChanged or changed;

        OptionsMenu.DecreaseIndent();
    end

    -------------------- Crown Tracker --------------------

    OptionsMenu.Header("Crown Tracker");

    if not CrownTracker.crownTableVisible and Settings.current.crownTracker.showCrownTracker then
        if OptionsMenu.Button("Open Crown Tracker", "Open") then
            CrownTracker.crownTableVisible = true;
        end
    end

    changed, Settings.current.crownTracker.showCrownTracker = OptionsMenu.CheckBox("Show crown tracker", Settings.current.crownTracker.showCrownTracker);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.crownTracker.hideComplete = OptionsMenu.CheckBox("Hide completed monsters", Settings.current.crownTracker.hideComplete);
    settingsChanged = settingsChanged or changed;

    changed, Settings.current.crownTracker.showCurrentRecords = OptionsMenu.CheckBox("Show current records", Settings.current.crownTracker.showCurrentRecords);
    settingsChanged = settingsChanged or changed;
    
    changed, Settings.current.crownTracker.showSizeBorders = OptionsMenu.CheckBox("Show size borders", Settings.current.crownTracker.showSizeBorders);
    settingsChanged = settingsChanged or changed;

    if OptionsMenu.Button("Reset window position/size", "Click to reset", false) then
        CrownTracker.ResetWindow();
    end

    if settingsChanged then
        Settings.Save();
    end
end

-------------------------------------------------------------------

function NativeSettingsMenu.InitModule()
    Utils.logDebug("InitModule!");
    if NativeSettingsMenu.IsModuleAvailable("ModOptionsMenu.ModMenuApi") then
        OptionsMenu = require("ModOptionsMenu.ModMenuApi");
        if not OptionsMenu then
            Utils.logWarn("'ModOptionsMenu.ModMenuApi' not found. If you want to use the ingame menu to configure this mod you will need to install the ModOptionsMenu mod by BoltManGuy https://www.nexusmods.com/monsterhunterrise/mods/1292?tab=files&file_id=6275");
        elseif NativeSettingsMenu.Initialized == false then
            NativeSettingsMenu.Init();
            NativeSettingsMenu.Initialized = true;

            --add a callback here in order to hook when the user resets all settings
            ModMenu.OnResetAllSettings = NativeSettingsMenu.Reset;
        end
    end
end

-------------------------------------------------------------------

function NativeSettingsMenu.Reset()
    Settings.ResetToDefault();
end

-------------------------------------------------------------------

return NativeSettingsMenu;