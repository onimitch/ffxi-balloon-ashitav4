local defines = T{}

defines.chat_color_codes = T{
    -- color code 1 (black/reset)
    standard = string.char(0x1E,0x01),
    -- color code 2 (green/regular items)
    item = string.char(0x1E,0x02),
    -- color code 3 (blue/key items)
    key_item = string.char(0x1E,0x03),
    -- color code 4 (blue/???)
    blue = string.char(0x1E,0x04),
    -- color code 5 (magenta/equipment?)
    magenta = string.char(0x1E,0x05),
    -- color code 6 (cyan/???)
    cyan = string.char(0x1E,0x06),
    -- color code 7 (yellow/???)
    yellow = string.char(0x1E,0x07),
    -- color code 8 (orange/RoE objectives?)
    orange = string.char(0x1E,0x08),

    emote = string.char(0x1F,0x0F),

    -- characters used to start a color code
    -- leadchars = string.char(0x1E, 0x1F),
}

defines.chat_modes = T{
    say = 9,
    shout = 10,
    yell = 11,
    tell = 12,
    party = 13,
    linkshell = 14,
    emote = 15,
    player = 36, -- Player defeats the Tiny Mandragora.
    others = 37, -- (maybe party?) Tenzen defeats the Beach Bunny.
    other_defeated = 44, -- Non party members?
    synth = 121,
    battle = 122, -- You defeated a designated target. (Progress: 1/4)
    misc_message2 = 142,
    misc_message3 = 144,
    item_recieve = 146, -- Player recieved item
    misc_message = 148, -- Goblin spinner items, fishing messages, training accepted/cancelled
    message = 150,
    system = 151,
    unity = 212,
    linkshell2 = 214,
    assistj = 220,
    assiste = 222,
}

defines.packets = {
    inc = {
        zone_update = 0x00A,
        zone_out = 0x00B,
        leave_conversation = 0x052,
        mog_menu = 0x02E,
        npc_interact1a = 0x032,
        npc_interact1b = 0x033,
        npc_interact2 = 0x034,
    },
    out = {
        action = 0x01A,
        dialogue_option = 0x05B,
        homepoint_map = 0x114,
    },
}

-- 0x31-0x33 and 0x37 all appear the same
--defines.PROMPT_CHARS = string.char(0x7F,0x31)
-- the 0x01 in this is the number of seconds before the prompt continues itself
-- 0x34-0x36 seem to do the same thing
defines.AUTO_PROMPT_CHARS = string.char(0x7F,0x34,0x01)

defines.PROMPT_CHARS = {
    string.char(0x7F,0x31),
    string.char(0x7F,0x32),
    string.char(0x7F,0x33),
    string.char(0x7F,0x34),
    string.char(0x7F,0x35),
    string.char(0x7F,0x36),
    string.char(0x7F,0x37),
}

-- Auto prompt usually seen like 0x7F,0x34,0x01, where the 0x01 is the number of seconds before the prompt continues itself
defines.auto_prompt_chars_pattern = '[\127][\49\50\51\52\53\54\55][\01\02\03\04\05\06]'
-- Normal prompt doesn't have the third character at the end
defines.prompt_chars_pattern = '[\127][\49\50\51\52\53\54\55]'

-- Mouse state
defines.MOUSE_DOWN = 513
defines.MOUSE_UP = 514

-- 48 Square, 49 Cross, 50 Circle, 51 Triangle
defines.DINPUT_CONTROLLER_DISMISS = S{49, 50}
-- 12 A, 13 B, 14 X, 15 Y
defines.XINPUT_CONTROLLER_DISMISS = S{12, 13}


return defines