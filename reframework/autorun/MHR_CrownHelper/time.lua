local Time = {};

local application = sdk.get_native_singleton("via.Application");
local applicationTypeDef = sdk.find_type_definition("via.Application");
local getFrameTimeMilliseconds = applicationTypeDef:get_method("get_FrameTimeMillisecond");

Time.timeTotal = 0;
Time.timeDelta = 0;

-------------------------------------------------------------------

function Time.Tick()
    Time.timeDelta = getFrameTimeMilliseconds:call(application) * 0.01;
    Time.timeTotal = os.clock();
end

-------------------------------------------------------------------

return Time;