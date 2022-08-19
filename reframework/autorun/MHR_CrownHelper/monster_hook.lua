local monster_hook = {};
local singletons;

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

local recorded_monsters =  {};
local known_big_monsters = {};

-- queue of monsters to work trough
local monster_buffer = {};

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
            log.debug("Large");
            monster_hook.NewMonster(enemy);
        end
    end



end

function monster_hook.NewMonster(enemy)
    local monster = {};
    -- type
    local enemy_type = enemy_type_field:get_data(enemy);
    if enemy_type ~= nil then
        monster.id = enemy_type;
    else
        log.error("Invalid enemy type");
    end

    -- name
    local enemy_name = get_enemy_name_message_method:call(singletons.MessageManager, enemy_type);
    if enemy_name ~= nil then
        monster.name = enemy_name;
    end

    log.debug(enemy_name);

    -- size
    local size_info = find_enemy_size_info_method:call(singletons.EnemyManager, enemy_type);

    if size_info ~= nil then
        local small_border = get_small_border_method:call(size_info);
        local big_border = get_big_border_method:call(size_info);
        local king_border = get_king_border_method:call(size_info);

        local size = get_monster_list_register_scale_method:call(enemy);

        if size ~= nil then
            monster.size = size;

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
        end
    end

    monster_buffer[#monster_buffer+1] = monster;
end

local function Copy(t)
    local u = { }
    for k, v in pairs(t) do u[k] = v end
    return u;
end

function monster_hook.Pop()
    local monster = Copy(monster_buffer[#monster_buffer]);
    monster_buffer[#monster_buffer] = nil;
    return monster;
end

function monster_hook.BufferCount()
    return #monster_buffer;
end

function monster_hook.InitModule()
    singletons = require("MHR_CrownHelper.singletons");

    sdk.hook(enemy_character_base_update_method, 
        function(args)
            pcall(monster_hook.update_monster, sdk.to_managed_object(args[2]));
        end,
        function(retval)
            return retval;
        end);
end

return monster_hook;