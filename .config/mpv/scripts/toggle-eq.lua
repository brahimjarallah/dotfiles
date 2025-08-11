local mp = require 'mp'
local eq_presets = {
    ["load-jazz"] = "lavfi=[equalizer=f=32:t=q:w=1:g=-2,equalizer=f=64:t=q:w=1:g=-2,equalizer=f=125:t=q:w=1:g=-1,equalizer=f=250:t=q:w=1:g=2,equalizer=f=500:t=q:w=1:g=3,equalizer=f=1000:t=q:w=1:g=2,equalizer=f=2000:t=q:w=1:g=1,equalizer=f=4000:t=q:w=1:g=0,equalizer=f=8000:t=q:w=1:g=2,equalizer=f=16000:t=q:w=1:g=3]",
    ["load-dance"] = "lavfi=[equalizer=f=32:t=q:w=1:g=4,equalizer=f=64:t=q:w=1:g=4,equalizer=f=125:t=q:w=1:g=3,equalizer=f=250:t=q:w=1:g=2,equalizer=f=500:t=q:w=1:g=1,equalizer=f=1000:t=q:w=1:g=0,equalizer=f=2000:t=q:w=1:g=0,equalizer=f=4000:t=q:w=1:g=2,equalizer=f=8000:t=q:w=1:g=3,equalizer=f=16000:t=q:w=1:g=4]",
    ["clear"] = "",
}

mp.register_script_message("load-jazz", function()
    mp.set_property("af", eq_presets["load-jazz"])
    mp.osd_message("🎷 Jazz EQ Enabled")
end)

mp.register_script_message("load-dance", function()
    mp.set_property("af", eq_presets["load-dance"])
    mp.osd_message("💃 Dance EQ Enabled")
end)

mp.register_script_message("clear", function()
    mp.set_property("af", eq_presets["clear"])
    mp.osd_message("❌ Equalizer Off")
end)

