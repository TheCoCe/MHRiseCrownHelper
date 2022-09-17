local Monsters = {};
local Singletons    = require("MHR_CrownHelper.Singletons");
local Quests        = require("MHR_CrownHelper.Quests");
local Utils         = require("MHR_CrownHelper.Utils");
local table_helpers = require("MHR_CrownHelper.table_helpers")
local Event         = require("MHR_CrownHelper.Event")
local Notifications = require("MHR_CrownHelper.Notifications")
local Drawing       = require("MHR_CrownHelper.Drawing")
local Settings      = require("MHR_CrownHelper.Settings")

---@class EmType
---@class Enemy

local enemyCharacterBaseTypeDef = sdk.find_type_definition("snow.enemy.EnemyCharacterBase");
local enemyCharacterBaseUpdateMethod = enemyCharacterBaseTypeDef:get_method("update");

local isBossEnemyMethod = enemyCharacterBaseTypeDef:get_method("get_isBossEnemy");

local enemyTypeField = enemyCharacterBaseTypeDef:get_field("<EnemyType>k__BackingField");

-- enemy name
local messageManagerTypeDef = sdk.find_type_definition("snow.gui.MessageManager");
local getEnemyNameMessageMethod = messageManagerTypeDef:get_method("getEnemyNameMessage(snow.enemy.EnemyDef.EmTypes)");
-- monster size methods
local getMonsterListRegisterScaleMethod = enemyCharacterBaseTypeDef:get_method("get_MonsterListRegisterScale");
-- monster size definitions
local enemyManagerTypeDef = sdk.find_type_definition("snow.enemy.EnemyManager");
local findEnemeySizeInfoMethod = enemyManagerTypeDef:get_method("findEnemySizeInfo(snow.enemy.EnemyDef.EmTypes)");
local convertEnemyTypeIndexMethod = enemyManagerTypeDef:get_method("convertEnemyTypeIndex(snow.enemy.EnemyDef.EmTypes)");
-- monster crown borders
local sizeInfoReturnType = findEnemeySizeInfoMethod:get_return_type();
local getSmallBorderMethod = sizeInfoReturnType:get_method("get_SmallBorder");
local getBigBorderMethod = sizeInfoReturnType:get_method("get_BigBorder");
local getKingBorderMethod = sizeInfoReturnType:get_method("get_KingBorder");
-- id
local getSetInfoMethod = enemyCharacterBaseTypeDef:get_method("get_SetInfo");
local setInfoReturnType = getSetInfoMethod:get_return_type();
local getUniqueIdMethod = setInfoReturnType:get_method("get_UniqueId");
-- HunterRecordManager -> get size infos (in quest and village)
local recordManagerTypeDef = sdk.find_type_definition("snow.HunterRecordManager");
local recordIsSmallCrownMethod = recordManagerTypeDef:get_method("isSmallCrown(snow.enemy.EnemyDef.EmTypes, snow.enemy.EnemyDef.EnemyTypeIndex, System.Single)");
local recordIsBigCrownMethod = recordManagerTypeDef:get_method("isBigCrown(snow.enemy.EnemyDef.EmTypes, snow.enemy.EnemyDef.EnemyTypeIndex, System.Single)");
local recordIsKingCrownMethod = recordManagerTypeDef:get_method("isKingCrown(snow.enemy.EnemyDef.EmTypes, snow.enemy.EnemyDef.EnemyTypeIndex, System.Single)");

local recordIsEnemySmallCrownMethod = recordManagerTypeDef:get_method("isEnemySmallCrown(snow.enemy.EnemyDef.EnemyTypeIndex)");
local recordIsEnemyBigCrownMethod = recordManagerTypeDef:get_method("isEnemyBigCrown(snow.enemy.EnemyDef.EnemyTypeIndex)");
local recordIsEnemyKingCrownMethod = recordManagerTypeDef:get_method("isEnemyKingCrown(snow.enemy.EnemyDef.EnemyTypeIndex)");
local recordIsCrownEnableMethod = recordManagerTypeDef:get_method("isCrownEnable(snow.enemy.EnemyDef.EnemyTypeIndex)");


-- Gets the current amount of boss enemies in the map.
local getBossEnemyCountMethod = enemyManagerTypeDef:get_method("getBossEnemyCount");
-- Gets the boss enemy from an index.
local getBossEnemyMethod = enemyManagerTypeDef:get_method("getBossEnemy");

-- this represents monsters that are currently on the map
local currentMapMonsters = {};
local orderedMapMonsters = {};

-- key: enemy, value: bool monster recorded
local recordedMonsters = {};
-- key: enemy, value: bool is big monster
local knownBigMonsters = {};
-- Registered monsters k[enemy], v[monster] 
Monsters.monsters = {};
-- All available monster types k[emType], v[table]
Monsters.monsterDefinitions = {};

local currentInterval = 0.0;
Monsters.UpdateInterval = 5.0;

Monsters.onMonsterAdded = Event.New();
Monsters.onMonsterRemoved = Event.New();

local monsterDebugIndex = 0;

-------------------------------------------------------------------

function Monsters.OnGameStatusChangedCallback()
    if Quests.gameStatus == 1 then
        -- Update the size infos when coming back to village
        Monsters.InitSizeInfos();
        Monsters.InitList();
    end
    
    -- player on quest
    if Quests.gameStatus == 2 then
        -- Clear the outdated monster list when on a new quest
        Monsters.InitList();
    end
end

-------------------------------------------------------------------

function Monsters.Update(deltaTime)
    if currentInterval > 0 then
        currentInterval = currentInterval - deltaTime;
        return;
    end
    currentInterval = Monsters.UpdateInterval;

    local tempMonsters = {};
    orderedMapMonsters = {};

    -- get current boss enemy count on the map
    local enemyCount = getBossEnemyCountMethod(Singletons.EnemyManager);
    if enemyCount == nil then
        return;
    end

    -- iterate over all enemies
    for i = 0, enemyCount - 1, 1 do
        -- get the enemy
        local enemy = getBossEnemyMethod(Singletons.EnemyManager, i);
        if enemy == nil then
            goto continue;
        end
        -- get the monster from the enemy
        local monster = Monsters.GetMonster(enemy);

        if monster ~= nil then
            tempMonsters[enemy] = monster;

            if currentMapMonsters[enemy] == nil then
                -- temp contains, current doesn't -> new monster
                Monsters.onMonsterAdded(monster);
            end

            -- Save this to an array because we need the order
            orderedMapMonsters[#orderedMapMonsters+1] = monster;
        end

        ::continue::
    end

    -- check the other way to find monsters that were registered but are no longer on the map
    for enemy, monster in pairs(currentMapMonsters) do
        if tempMonsters[enemy] == nil then
            -- temp doesnt contain, current contains -> monster removed
            Monsters.onMonsterRemoved(monster);
        end
    end

    currentMapMonsters = tempMonsters;
end

-------------------------------------------------------------------

--- Monster hook function.
---@param enemy Enemy The enemy provided by the hook
function Monsters.UpdateMonster(enemy)
    if enemy == nil then
        return;
    end

    -- new monster
    if not recordedMonsters[enemy] then
        recordedMonsters[enemy] = true;

        if not knownBigMonsters[enemy] then
            knownBigMonsters[enemy] = isBossEnemyMethod(enemy);
        end

        local is_large = knownBigMonsters[enemy];
        if is_large == nil then
            return;
        end

        if is_large then
            Monsters.NewMonster(enemy);
        end
    end
end

-------------------------------------------------------------------

---Registers and caches a new monster from the provided enemy
---@param enemy Enemy
---@return table monster The newly created monster table.
function Monsters.NewMonster(enemy)

    -- create a new monster
    local monster = {};

    -- id
    local setInfo = getSetInfoMethod(enemy);
    if setInfo ~= nil then
        local uniqueId = getUniqueIdMethod(setInfo);
        if uniqueId ~= nil then
            monster.uniqueId = uniqueId;
        end
    end

    -- type
    local emType = enemyTypeField:get_data(enemy);
    if emType ~= nil then
        monster.emType = emType;
    else
        Utils.logError("Invalid enemy type");
    end

    -- name
    local enemyName = getEnemyNameMessageMethod(Singletons.MessageManager, emType);
    if enemyName ~= nil then
        monster.name = enemyName;
    end

    -- size
    local sizeInfo = Monsters.GetSizeInfoForEnemyType(emType, false);

    if sizeInfo ~= nil then
        local size = getMonsterListRegisterScaleMethod(enemy);
        --[[
        if monsterDebugIndex == 0 then
            size = 1.234;
        elseif monsterDebugIndex == 1 then
            size = 1.05;
        elseif monsterDebugIndex == 2 then
            size = 1.2;
        elseif monsterDebugIndex == 3 then
            size = 0.89;
        end

        monsterDebugIndex = monsterDebugIndex + 1;
        ]]

        if size ~= nil then
            monster.size = size;

            local enemyTypeIndex = convertEnemyTypeIndexMethod(Singletons.EnemyManager, emType);
            monster.isSmall = recordIsSmallCrownMethod(Singletons.HunterRecordManager, emType, enemyTypeIndex, size);
            monster.isBig = recordIsBigCrownMethod(Singletons.HunterRecordManager, emType, enemyTypeIndex, size);
            monster.isKing = recordIsKingCrownMethod(Singletons.HunterRecordManager, emType, enemyTypeIndex, size);
        end

        if (monster.isSmall or (monster.isBig and not Settings.current.notifications.ignoreSilverCrowns) or monster.isKing) and 
            (sizeInfo.crownNeeded or not Settings.current.notifications.ignoreObtainedCrowns) then
            local crownString = monster.isSmall and "Mini" or (monster.isKing and "Gold" or (monster.isBig and "Silver"));
            crownString = crownString .. " Crown " .. monster.name .. " spotted!"
            local icon = monster.isSmall and "miniCrown" or (monster.isKing and "kingCrown" or (monster.isBig and "bigCrown"));
            Notifications.AddNotification(crownString, Drawing.imageResources[icon]);
        end
    end

    local sizeString = (monster.isSmall and "[small]" or (monster.isKing and "[king]" or (monster.isBig and "[big]" or "")));
    Utils.logDebug("MHR_CrownHelper: registered '" .. enemyName .. "' \tSize: '" ..  string.format("%.2f", monster.size) .. "' " .. sizeString);

    if Monsters.monsters[enemy] == nil then
        Monsters.monsters[enemy] = monster;
    end

    return monster;
end

-------------------------------------------------------------------

---Get the chached monster info from the enemy.
---If this monster has not been cached yet, it will be when called.
---@param enemy Enemy
---@return table monster The cached monster table.
function Monsters.GetMonster(enemy)
    local monster = Monsters.monsters[enemy];
    if monster == nil then
        monster = Monsters.NewMonster(enemy);
    end
    return monster;
end

-------------------------------------------------------------------

---Iterates all known monsters and calls the provided function with it and its index.
---@param f function The function to call for each monster f(enemy, index)
function Monsters.IterateMonsters(f)
    for i = 1, #orderedMapMonsters, 1 do
        f(orderedMapMonsters[i], i - 1);
    end
end

-------------------------------------------------------------------

---Get the size info for the enemy type provided.
---Set the update flag to update the cached size info.
---@param emType EmType|nil
---@param update boolean
---@return table sizeInfo The cached size info table.
function Monsters.GetSizeInfoForEnemyType(emType, update)
    local monsterDef = Monsters.monsterDefinitions[emType];
    if not monsterDef then return {}; end

    if monsterDef.sizeInfo ~= nil and not update then
        return monsterDef.sizeInfo;
    else
        local monsterSizeInfo = findEnemeySizeInfoMethod(Singletons.EnemyManager, emType);

        -- get min and max hunted monster size
        local minHuntedSize = 0;
        local maxHuntedSize = 0;
        local guildCardSaveData = Singletons.GuildCardManager._GuildCard;
        if guildCardSaveData then
            local guildCardData = guildCardSaveData.MyData;
            if guildCardData then
                local enemySizeMinArray = guildCardData.EnemySizeMin;
                local enemySizeMaxArray = guildCardData.EnemySizeMax;
                if enemySizeMinArray and enemySizeMaxArray then
                    local minSizeElem = enemySizeMinArray:get_element(monsterDef.emTypeIndex);
                    if minSizeElem then
                        minHuntedSize = minSizeElem.mValue;
                    end
                    local maxSizeElem = enemySizeMaxArray:get_element(monsterDef.emTypeIndex);
                    if maxSizeElem then
                        maxHuntedSize = maxSizeElem.mValue;
                    end
                end
            end
        end

        if monsterSizeInfo ~= nil then
            local sizeInfo = {
                smallBorder = getSmallBorderMethod(monsterSizeInfo),
                bigBorder = getBigBorderMethod(monsterSizeInfo),
                kingBorder = getKingBorderMethod(monsterSizeInfo),
                smallCrownObtained = recordIsEnemySmallCrownMethod(Singletons.HunterRecordManager, monsterDef.emTypeIndex),
                bigCrownObtained = recordIsEnemyBigCrownMethod(Singletons.HunterRecordManager, monsterDef.emTypeIndex),
                kingCrownObtained = recordIsEnemyKingCrownMethod(Singletons.HunterRecordManager, monsterDef.emTypeIndex),
                minHuntedSize = minHuntedSize,
                maxHuntedSize = maxHuntedSize,
                crownNeeded = false,
                crownEnabled = recordIsCrownEnableMethod(Singletons.HunterRecordManager, monsterDef.emTypeIndex)
            };
            sizeInfo.crownNeeded = not sizeInfo.smallCrownObtained or not sizeInfo.bigCrownObtained or not sizeInfo.kingCrownObtained;
            -- set size info on monsterDefinition
            monsterDef.sizeInfo = sizeInfo;

            return sizeInfo;
        end
    end

    return {};
end

-------------------------------------------------------------------

---Initializes/empties the monster list.
function Monsters.InitList()
    Monsters.monsters = {};
    currentMapMonsters = {};
    orderedMapMonsters = {};
    recordedMonsters = {};
    knownBigMonsters = {};
end

-------------------------------------------------------------------

--- Initializes the enemyTypes list and caches enemyType, enemyTypeIndex and name.
function Monsters.InitEnemyTypesList()
    local enemyEnum = Utils.GenerateEnum("snow.enemy.EnemyDef.EmTypes");
    
    for _, emType in pairs(enemyEnum) do
        if emType > 0 then
            local monsterDefinition =  {
                emType = emType;
                emTypeIndex = convertEnemyTypeIndexMethod(Singletons.EnemyManager, emType);
                name = getEnemyNameMessageMethod(Singletons.MessageManager, emType);
            }

            Monsters.monsterDefinitions[emType] = monsterDefinition;
        end
    end
end

-------------------------------------------------------------------

--- Initializes all size infos
function Monsters.InitSizeInfos()
    for _, v in pairs(Monsters.monsterDefinitions) do
        Monsters.GetSizeInfoForEnemyType(v.emType, true);
    end
end

-------------------------------------------------------------------

-- initializes the module
function Monsters.InitModule()
    -- hook into the enemy update method
    sdk.hook(enemyCharacterBaseUpdateMethod,
        function(args)
            pcall(Monsters.UpdateMonster, sdk.to_managed_object(args[2]));
        end,
        function(retval)
            return retval;
        end);

    Monsters.InitEnemyTypesList();
    Monsters.InitSizeInfos();
    Quests.onGameStatusChanged:add(Monsters.OnGameStatusChangedCallback);
end

-------------------------------------------------------------------

return Monsters;
