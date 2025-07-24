Way late, but for others' reference:

The problem seems to be that xmodmap isn't identifying any of the keys you listed as modifier keys. AwesomeWM therefore doesn't allow them to be used as modifier keys.

You can try adding the key you want to use as Mod3 (which doesn't seem to be used for anything on most systems I've seen), then your rc.lua can list the modkey as "Mod3".

Add as a modifier key
You can see your modifier keys with xmodmap. By default you'll probably get something like this:

xmodmap:  up to 4 keys per modifier, (keycodes in parentheses):

shift       Shift_L (0x32),  Shift_R (0x3e)
lock        Caps_Lock (0x42)
control     Control_L (0x25),  Control_R (0x69)
mod1        Alt_L (0x40),  Alt_R (0x6c),  Meta_L (0xcd)
mod2        Num_Lock (0x4d)
mod3      
mod4        Super_L (0x85),  Super_R (0x86),  Super_L (0xce),  Hyper_L (0xcf)
mod5        ISO_Level3_Shift (0x5c),  Mode_switch (0xcb)
With xev you can see the name of any key you press while it's running, and for Scroll Lock mine shows up as:

KeyPress event, serial 36, synthetic NO, window 0x2200001,
    root 0x225, subw 0x0, time 23086947, (433,729), root:(470,783),
    state 0x0, keycode 78 (keysym 0xff14, Scroll_Lock), same_screen YES,
    XLookupString gives 0 bytes: 
    XmbLookupString gives 0 bytes: 
    XFilterEvent returns: False

KeyRelease event, serial 36, synthetic NO, window 0x2200001,
    root 0x225, subw 0x0, time 23087091, (433,729), root:(470,783),
    state 0x0, keycode 78 (keysym 0xff14, Scroll_Lock), same_screen YES,
    XLookupString gives 0 bytes: 
    XFilterEvent returns: False
You'll notice the name of the keysym is Scroll_Lock.

To add to Mod3, you need to create or add to ~/.Xmodmap. Adding this line sets Mod3 to be only the Scroll_Lock key:

add Mod3 = Scroll_Lock
To test your changes and see any errors in your .Xmodmap file, run

xmodmap ~/.Xmodmap
Updating rc.lua
As you've clearly already figured out, toward the top of your rc.lua file (which is usually in ~/.config/awesome/rc.lua), there's a modkey = "Mod4" line. Change this to modkey = "Mod3".

Warnings
The Esc key is used for a number of key mappings by AwesomeWM. I'd suggest trying Scroll Lock or Pause instead since it's less likely to have extensive conflicts. In fact AwesomeWM seems to assume Esc is reserved for canceling the current operation.

Scroll Lock seems to be magically treated as a locking key, much like Caps Lock. The difference is that the locking behavior of Caps Lock is relatively trivial to disable, while Scroll Lock can't have this behavior disabled as far as I can tell.

I'd suggest trying this with a key like the Numpad 0 key, or something that's not normally designed to be a state locking key, confirm it works, then try switching to the key you want.
