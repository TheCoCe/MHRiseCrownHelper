local Monsters = {};
local Singletons = require("MHR_CrownHelper.Singletons");

local enemyCharacterBaseTypeDef = sdk.find_type_definition("snow.enemy.EnemyCharacterBase");
local enemyCharacterBaseUpdateMethod = enemyCharacterBaseTypeDef:get_method("update");

local isBossEnemyMethod = enemyCharacterBaseTypeDef:get_method("get_isBossEnemy");

local enemyTypeField = enemyCharacterBaseTypeDef:get_field("<EnemyType>k__BackingField");

-- enemy name
local messageManagerTypeDef = sdk.find_type_definition("snow.gui.MessageManager");
local getEnemyNameMessageMethod = messageManagerTypeDef:get_method("getEnemyNameMessage");
-- monster size methods
local getMonsterListRegisterScaleMethod = enemyCharacterBaseTypeDef:get_method("get_MonsterListRegisterScale");
-- monster size definitions
local enemyManagerTypeDef = sdk.find_type_definition("snow.enemy.EnemyManager");
local findEnemeySizeInfoMethod = enemyManagerTypeDef:get_method("findEnemySizeInfo");
-- monster crown borders
local sizeInfoReturnType = findEnemeySizeInfoMethod:get_return_type();
local getSmallBorderMethod = sizeInfoReturnType:get_method("get_SmallBorder");
local getBigBorderMethod = sizeInfoReturnType:get_method("get_BigBorder");
local getKingBorderMethod = sizeInfoReturnType:get_method("get_KingBorder");
-- id
local getSetInfoMethod = enemyCharacterBaseTypeDef:get_method("get_SetInfo");
local setInfoReturnType = getSetInfoMethod:get_return_type();
local getUniqueIdMethod = setInfoReturnType:get_method("get_UniqueId");
-- hunter record
local recordManagerTypeDef = sdk.find_type_definition("snow.HunterRecordManager");
local recordIsSmallCrownMethod = recordManagerTypeDef:get_method("isSmallCrown");
local recordIsBigCrownMethod = recordManagerTypeDef:get_method("isBigCrown");
local recordIsKingCrownMethod = recordManagerTypeDef:get_method("isKingCrown");

-- key: enemy, value: bool monster recorded
local recordedMonsters =  {};
-- key: enemy, value: bool is big monster
local knownBigMonsters = {};
-- registered monsters key: enemy, value: monster
Monsters.monsters = {};

-------------------------------------------------------------------

-- monster update hook
function Monsters.UpdateMonster(enemy)
    if enemy == nil then
        return;
    end

    -- new monster
    if not recordedMonsters[enemy] then
        recordedMonsters[enemy] = true;

        if not knownBigMonsters[enemy] then
            knownBigMonsters[enemy] = isBossEnemyMethod:call(enemy);
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

-- register a new large monster
function Monsters.NewMonster(enemy)
    
    -- create a new monster
    local monster = {};
    
    -- id
    local setInfo = getSetInfoMethod:call(enemy);
	if setInfo ~= nil then
		local uniqueId = getUniqueIdMethod:call(setInfo);
        if uniqueId ~= nil then
            monster.uniqueId = uniqueId;
        end
	end
    
    -- type
    local enemyType = enemyTypeField:get_data(enemy);
    if enemyType ~= nil then
        monster.id = enemyType;
    else
        log.error("MHR_CrownHelper: Invalid enemy type");
    end

    -- name
    local enemyName = getEnemyNameMessageMethod:call(Singletons.MessageManager, enemyType);
    if enemyName ~= nil then
        monster.name = enemyName;
    end

    -- size
    local sizeInfo = findEnemeySizeInfoMethod:call(Singletons.EnemyManager, enemyType);

    if sizeInfo ~= nil then
        local smallBorder = getSmallBorderMethod:call(sizeInfo);
        local bigBorder = getBigBorderMethod:call(sizeInfo);
        local kingBorder = getKingBorderMethod:call(sizeInfo);

        local size = getMonsterListRegisterScaleMethod:call(enemy);

        if size ~= nil then
            monster.size = size;

            -- get size borders
            if smallBorder ~= nil then
                monster.smallBorder = smallBorder;
                monster.isSmall = monster.size <= monster.smallBorder;
            end

            if bigBorder ~= nil then
                monster.bigBorder = bigBorder;
                monster.isBig = monster.size >= monster.bigBorder;
            end
            
            if kingBorder ~= nil then
                monster.kingBorder = kingBorder;
                monster.isKing = monster.size >= monster.kingBorder;
            end

            -- check crowns
            monster.crownNeeded = false;

            if monster.isSmall and not recordIsSmallCrownMethod(Singletons.HunterRecordManager, monster.id) then
                monster.crownNeeded = true;
            end
            -- prioritize king crowns
            if monster.isKing and not recordIsKingCrownMethod(Singletons.HunterRecordManager, monster.id) then
                monster.crownNeeded = true;
            elseif monster.isBig and not recordIsBigCrownMethod(Singletons.HunterRecordManager, monster.id) then
                monster.crownNeeded = true;
            end
        end
    end

    log.debug("MHR_CrownHelper: registered '" .. enemyName .. "' size '" .. monster.size .. "'");

    if Monsters.monsters[enemy] == nil then
        Monsters.monsters[enemy] = monster;
    end

    return monster;
end

-------------------------------------------------------------------

-- get a monster from the enemy
function Monsters.GetMonster(enemy)
    local monster = Monsters.monsters[enemy];
    if monster == nil then
       monster = Monsters.NewMonster(enemy);
    end
    return monster;
end

-------------------------------------------------------------------

-- current enemies sdk methods
local getBossEnemyCountMethod = enemyManagerTypeDef:get_method("getBossEnemyCount");
local getBossEnemyMethod = enemyManagerTypeDef:get_method("getBossEnemy");

function Monsters.IterateMonsters(f)
    -- get current boss enemy count on the map
    local enemyCount = getBossEnemyCountMethod:call(Singletons.EnemyManager);
    if enemyCount == nil then
        return;
    end

    -- iterate over all enemies
    for i = 0, enemyCount - 1, 1 do
        -- get the enemy
        local enemy = getBossEnemyMethod:call(Singletons.EnemyManager, i);
        if enemy == nil then
            goto continue;
        end
        -- get the monster from the enemy
        local monster = Monsters.GetMonster(enemy);

        if monster ~= nil then
            -- call delegate with the monster and it's corresponding index
            f(monster, i);
        end

        ::continue::
    end
end

-------------------------------------------------------------------

-- initializes/empties the monster list
function Monsters.InitList()
    Monsters.monsters = {};
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
end

return Monsters;