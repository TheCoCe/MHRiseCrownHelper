local time = {};

local application = sdk.get_native_singleton("via.Application");
local application_type_def = sdk.find_type_definition("via.Application");
local get_frame_time_mil_method = application_type_def:get_method("get_FrameTimeMillisecond");

time.time_total = 0;
time.time_delta = 0;

function time.tick()
    time.time_delta = get_frame_time_mil_method:call(application) * 0.01;
    time.time_total = os.clock();
end

return time;