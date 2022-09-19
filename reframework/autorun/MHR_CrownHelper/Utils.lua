local Utils = {};

local nameString = "[MHRCrownHelper]: ";

Utils.debugMode = false;

--[[ Logging ]]--
-------------------------------------------------------------------

--- Logs a info message
---@param message string
function Utils.logInfo(message)
    log.info(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a warning message
---@param message string
function Utils.logWarn(message)
    log.warn(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a error message
---@param message string
function Utils.logError(message)
    log.error(nameString .. message);
end

-------------------------------------------------------------------

--- Logs a debug message
---@param message string
function Utils.logDebug(message)
    if Utils.debugMode then
        log.debug(nameString .. message);
    end
end

--[[ Enums ]]--
-------------------------------------------------------------------

function Utils.GenerateEnum(typename)
    local t = sdk.find_type_definition(typename)
    if not t then return {} end

    local fields = t:get_fields()
    local enum = {}

    for _, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)

            enum[name] = raw_value
        end
    end

    return enum
end

-------------------------------------------------------------------

--see: https://stackoverflow.com/questions/15429236/how-to-check-if-a-module-exists-in-lua
function Utils.IsModuleAvailable(name)
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

-------------------------------------------------------------------

return Utils;