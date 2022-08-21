local monster_hook = {};
local singletons = require("MHR_CrownHelper.singletons");

local enemy_character_base_type_def = sdk.find_type_definition("snow.enemy.EnemyCharacterBase");
local enemy_character_base_update_method = enemy_character_base_type_def:get_method("update");

local is_boss_enemy_method = enemy_character_base_type_def:get_method("get_isBossEnemy");

local enemy_type_field = enemy_character_base_type_def:get_field("<EnemyType>k__BackingField");

-- enemy name
local message_manager_type_def = sdk.find_type_definition("snow.gui.MessageManager");
local get_enemy_name_message_method = message_manager_type_def:get_method("getEnemyNameMessage");
-- monster size methods
local get_monster_list_register_scale_method = enemy_character_base_type_def:get_method("get_MonsterListRegisterScale");
-- monster size definitions
local enemy_manager_type_def = sdk.find_type_definition("snow.enemy.EnemyManager");
local find_enemy_size_info_method = enemy_manager_type_def:get_method("findEnemySizeInfo");
-- monster crown borders
local size_info_type = find_enemy_size_info_method:get_return_type();
local get_small_border_method = size_info_type:get_method("get_SmallBorder");
local get_big_border_method = size_info_type:get_method("get_BigBorder");
local get_king_border_method = size_info_type:get_method("get_KingBorder");
-- id
local get_set_info_method = enemy_character_base_type_def:get_method("get_SetInfo");
local set_info_type = get_set_info_method:get_return_type();
local get_unique_id_method = set_info_type:get_method("get_UniqueId");
-- hunter record
local record_manager_type_def = sdk.find_type_definition("snow.HunterRecordManager");
local record_mini_method = record_manager_type_def:get_method("isSmallCrown");
local record_big_method = record_manager_type_def:get_method("isBigCrown");
local record_king_method = record_manager_type_def:get_method("isKingCrown");

-- key: enemy, value: bool monster recorded
local recorded_monsters =  {};
-- key: enemy, value: bool is big monster
local known_big_monsters = {};
-- registered monsters key: enemy, value: monster
local monsters = {};

-------------------------------------------------------------------

-- monster update hook
function monster_hook.update_monster(enemy)
    if enemy == nil then
        return;
    end

    -- new monster
    if not recorded_monsters[enemy] then
        recorded_monsters[enemy] = true;

        if not known_big_monsters[enemy] then
            known_big_monsters[enemy] = is_boss_enemy_method:call(enemy);
        end

        local is_large = known_big_monsters[enemy];
        if is_large == nil then
            return;
        end

        if is_large then
            monster_hook.NewMonster(enemy);
        end
    end
end

-------------------------------------------------------------------

-- register a new large monster
function monster_hook.NewMonster(enemy)
    
    -- create a new monster
    local monster = {};
    
    -- id
    local set_info = get_set_info_method:call(enemy);
	if set_info ~= nil then
		local unique_id = get_unique_id_method:call(set_info);
        if unique_id ~= nil then
            monster.unique_id = unique_id;
        end
	end
    
    -- type
    local enemy_type = enemy_type_field:get_data(enemy);
    if enemy_type ~= nil then
        monster.id = enemy_type;
    else
        log.error("MHR_CrownHelper: Invalid enemy type");
    end

    -- name
    local enemy_name = get_enemy_name_message_method:call(singletons.MessageManager, enemy_type);
    if enemy_name ~= nil then
        monster.name = enemy_name;
    end

    -- size
    local size_info = find_enemy_size_info_method:call(singletons.EnemyManager, enemy_type);

    if size_info ~= nil then
        local small_border = get_small_border_method:call(size_info);
        local big_border = get_big_border_method:call(size_info);
        local king_border = get_king_border_method:call(size_info);

        local size = get_monster_list_register_scale_method:call(enemy);

        if size ~= nil then
            monster.size = size;

            -- get size borders
            if small_border ~= nil then
                monster.small_border = small_border;
                monster.is_small = monster.size <= monster.small_border;
            end

            if big_border ~= nil then
                monster.big_border = big_border;
                monster.is_big = monster.size >= monster.big_border;
            end
            
            if king_border ~= nil then
                monster.king_border = king_border;
                monster.is_king = monster.size >= monster.king_border;
            end

            -- check crowns
            monster.crown_needed = false;

            if monster.is_small and not record_mini_method(singletons.HunterRecordManager, monster.id) then
                monster.crown_needed = true;
            end
            -- prioritize king crowns
            if monster.is_king and not record_king_method(singletons.HunterRecordManager, monster.id) then
                monster.crown_needed = true;
            elseif monster.is_big and not record_big_method(singletons.HunterRecordManager, monster.id) then
                monster.crown_needed = true;
            end
        end
    end

    log.debug("MHR_CrownHelper: registered '" .. enemy_name .. "' size '" .. monster.size .. "'");

    if monsters[enemy] == nil then
        monsters[enemy] = monster;
    end

    return monster;
end

-------------------------------------------------------------------

-- get a monster from the enemy
function monster_hook.GetMonster(enemy)
    local monster = monsters[enemy];
    if monster == nil then
       monster = monster_hook.NewMonster(enemy);
    end
    return monster;
end

-------------------------------------------------------------------

-- current enemies sdk methods
local get_boss_enemy_count_method = enemy_manager_type_def:get_method("getBossEnemyCount");
local get_boss_enemy_method = enemy_manager_type_def:get_method("getBossEnemy");

function monster_hook.InterateMonsters(f)
    -- get current boss enemy count on the map
    local enemyCount = get_boss_enemy_count_method:call(singletons.EnemyManager);
    if enemyCount == nil then
        return;
    end

    -- iterate over all enemies
    for i = 0, enemyCount - 1, 1 do
        -- get the enemy
        local enemy = get_boss_enemy_method:call(singletons.EnemyManager, i);
        if enemy == nil then
            goto continue;
        end
        -- get the monster from the enemy
        local monster = monster_hook.GetMonster(enemy);

        if monster ~= nil then
            -- call delegate with the monster and it's corresponding index
            f(monster, i);
        end

        ::continue::
    end
end

-------------------------------------------------------------------

-- initializes/empties the monster list
function monster_hook.InitList()
    monsters = {};
end

-------------------------------------------------------------------

-- initializes the module
function monster_hook.InitModule()
    -- hook into the enemy update method
    sdk.hook(enemy_character_base_update_method, 
        function(args)
            pcall(monster_hook.update_monster, sdk.to_managed_object(args[2]));
        end,
        function(retval)
            return retval;
        end);
end

return monster_hook;