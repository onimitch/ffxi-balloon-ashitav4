addon.name      = 'balloon'
addon.author    = 'Originally by Hando, English support added by Yuki & Kenshi, themes added by Ghosty, ported to Ashita v4 by onimitch.'
addon.version   = '4.1.0'
addon.desc      = 'Displays NPC chat logs in a UI Balloon, similar to FFXIV.'
addon.link      = 'https://github.com/onimitch/ffxi-balloon-ashitav4'

-- Ashita libs
require('common')
local chat = require('chat')
local settings = require('settings')
local encoding = require('gdifonts.encoding')

-- Windower lua libs
texts = require('wlibs.texts')
images = require('wlibs.images')
require('wlibs.sets')

-- Balloon files
local default_settings = require('defaults')
local theme = require('theme')
local ui = require('ui')
local tests = require('tests')
local defines = require('defines')


local chat_modes = defines.chat_modes
local chat_color_codes = defines.chat_color_codes

local balloon = {
    debug = 'off',
    debug_closing = false,
    waiting_to_close = false,
    close_timer = 0,
    last_text = '',
    last_mode = 0,
    processing_message = false,
    lang_code = 'en',
    settings = {},
    last_frame_time = 0,
    theme_options = nil,
    move_check_sensitivity = 0.01,
    in_mog_menu = false,
    in_menu = false,
    drag_offset = nil,
    accepted_chat_modes = {},
}

-- parses a string into char[hex bytecode]
local function parse_codes(str)
	return (str:gsub('.', function (c)
		return string.format('[%02X]', string.byte(c))
	end))
end

local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
local function get_game_menu_name()
    local menu_pointer = ashita.memory.read_uint32(pGameMenu)
    local menu_val = ashita.memory.read_uint32(menu_pointer)
    if (menu_val == 0) then
        return ''
    end
    local menu_header = ashita.memory.read_uint32(menu_val + 4)
    local menu_name = ashita.memory.read_string(menu_header + 0x46, 16)
    return string.gsub(menu_name, '\x00', ''):trimex()
end
local function is_chat_open()
    local menu_name = get_game_menu_name()
    return menu_name:match('menu[%s]+inline')
end

-------------------------------------------------------------------------------

balloon.initialize = function(new_settings)
    -- Get game language
    local lang = AshitaCore:GetConfigurationManager():GetInt32('boot', 'ashita.language', 'playonline', 2)
    balloon.lang_code = lang == 1 and 'ja' or 'en'

    -- Default chat modes that are always on
    balloon.accepted_chat_modes = S{
        chat_modes.message,
        chat_modes.system,
    }

    -- Get additional chat modes from settings
    local additional_chat_modes = balloon.settings.additional_chat_modes or {}
    for _, v in ipairs(additional_chat_modes) do
        balloon.accepted_chat_modes:add(v)
    end
    local chat_mode_list = balloon.accepted_chat_modes:concat(' ')

    -- Remove old filter setting
    if balloon.settings.filter ~= nil then
        balloon.settings.filter = nil
    end

	balloon.load_theme()

    if balloon.theme_options ~= nil and new_settings == nil then
        print(chat.header(addon.name):append(chat.message('Theme "%s", language: %s, chat modes: %s'):format(balloon.settings.theme, balloon.lang_code, chat_mode_list)))
    end
end

balloon.load_theme = function()
    -- Load the theme
    balloon.theme_options = theme.load(balloon.settings.theme, balloon.lang_code)
    if balloon.theme_options == nil then
        return
    end

    -- Load UI
	ui:load(balloon.settings, balloon.theme_options)
    ui:position(balloon.settings.position.x, balloon.settings.position.y)

    -- Display balloon if we changed theme while open
	if not ui:hidden() then
		balloon.process_balloon(balloon.last_text, balloon.last_mode)
	end
end

balloon.update_timer = function()
    if not balloon.waiting_to_close then
        return
    end
    if balloon.close_timer >= 0 then
        balloon.close_timer = math.max(0, balloon.close_timer - 1)
        ui.timer_text:text(balloon.close_timer..'')
    end

    if balloon.close_timer <= 0 then
        if balloon.debug_closing then print('Closing from timer') end
        balloon.close()
    else
        ashita.tasks.once(1, balloon.update_timer)
    end
end

balloon.open = function(timed)
	if timed then
		balloon.close_timer = balloon.settings.no_prompt_close_delay
		ui.timer_text:text(''..balloon.close_timer)
    else 
        balloon.close_timer = 0
        balloon.waiting_to_close = false
	end

	ui:show(timed)

    if timed and not balloon.waiting_to_close then
        balloon.waiting_to_close = true
        ashita.tasks.once(1, balloon.update_timer)
    end
end

balloon.close = function()
	ui:hide()

    balloon.waiting_to_close = false
    balloon.close_timer = 0
    balloon.in_mog_menu = false
    balloon.in_menu = false
end

balloon.handle_player_movement = function(player_entity)
    local new_player_pos = {
        player_entity.Movement.LocalPosition.X,
        player_entity.Movement.LocalPosition.Y,
        player_entity.Movement.LocalPosition.Z,
    }

    if not ui:hidden() and balloon.settings.move_close then
        if balloon.player_pos == nil then
            if balloon.debug_closing then print('Closing from move') end
            balloon.close()
        else
            local moved = {
                new_player_pos[1] - balloon.player_pos[1],
                new_player_pos[2] - balloon.player_pos[2],
                new_player_pos[3] - balloon.player_pos[3],
            }
            for _, v in ipairs(moved) do
                if math.abs(v) > balloon.move_check_sensitivity then
                    if balloon.debug_closing then print('Closing from move') end
                    balloon.close()
                    break
                end
            end
        end
    end

    balloon.player_pos = new_player_pos
end

balloon.process_incoming_message = function(e)
    -- Obtain the chat mode..
    local mode = bit.band(e.mode, 0x000000FF)

	-- log debug info
	if S{'mode', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Mode: ' .. mode .. ' Text: ' .. e.message) end

	-- skip text modes that aren't NPC speech
    if not balloon.accepted_chat_modes[mode] then
        if S{'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', ('Not accepted mode: %d'):format(mode)) end
        return
    end

    -- TODO: Check if this is correct, I think we should check it's actually a blank line, since currently this is only checking endswidth
	-- blank prompt line that auto-continues itself,
	-- usually used to clear a space for a scene change?
	if e.message:endswith(defines.AUTO_PROMPT_CHARS) then
        if balloon.debug_closing then 
            print('Closing from auto prompt chars')
            LogManager:Log(5, 'Balloon', 'Closed from ending with Auto prompt characters: ' .. parse_codes(e.message))
        end
		balloon.close()
		return
	end

	if balloon.settings.display_mode >= 1 then
		e.message_modified = balloon.process_balloon(e.message, mode)
    end
end

balloon.process_balloon = function(message, mode)
	balloon.last_text = message
	balloon.last_mode = mode

	-- detect whether messages have a prompt button
    local ends_with_prompt = false
    for _, v in ipairs(defines.PROMPT_CHARS) do
        ends_with_prompt = message:endswith(v)
        if ends_with_prompt then
            break
        end
    end
    local timed = (not balloon.in_menu and not ends_with_prompt)

	-- local timed = true
	-- if (S{chat_modes.message, chat_modes.system}[mode] and message:endswith(defines.PROMPT_CHARS[1]))
    --     or balloon.in_menu then -- or balloon.in_mog_menu 
	-- 	timed = false
	-- end

	-- Extract speaker name
    local npc_prefix_start, npc_prefix_end = message:find('.- : ')
	local npc_prefix = ''
    if npc_prefix_start ~= nil then
        if npc_prefix_end < 32 and npc_prefix_start > 0 then
            npc_prefix = message:sub(npc_prefix_start, npc_prefix_end)
        end
	end
	local npc_name = npc_prefix:sub(0, #npc_prefix-2)
	npc_name = npc_name:trimex()

    -- pass through the original message for the log
    local result = message

	-- mode 1, blank log lines and visible balloon
	if balloon.settings.display_mode == 1 then
        -- Preserve ending prompt chars
        local end_of_text_pos = #message
        for _, prompt_chars in ipairs(defines.PROMPT_CHARS) do
            local prompt_pos, _ = message:find(prompt_chars, -4, true)
            if prompt_pos ~= nil then
                end_of_text_pos = prompt_pos
                break
            end
        end
        result = npc_prefix
        if npc_prefix ~= '' then
            result = result .. '...'
        end
        -- Preserve prompt chars
        if end_of_text_pos == #message then
            -- Empty message
        else
            result = result .. message:sub(end_of_text_pos)
        end
	end

    -- strip the NPC name from the start of the message
    if npc_prefix ~= '' then
        message = message:sub(npc_prefix_end)
        -- message = message:gsub(npc_prefix:gsub('-', '--'), '')
    end

    -- log debug info
    if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'message: ' .. message) end
	if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'codes: ' .. parse_codes(message)) end
    if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'end codes shiftjis: ' .. parse_codes(message:sub(-4))) end

    -- Convert message to utf8
	message = balloon.convert_shiftjis_to_utf8(message)

	if S{'message+', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Pre-process: ' .. message) end
	if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'end codes utf8: ' .. parse_codes(message:sub(-4))) end

    -- TODO: Check if this is necessary (this was probably an issue with windower text color tags and opening with a \cr tag)
	-- strip the default color code from the start of messages,
	-- it causes the first part of the message to get cut off somehow
	local default_color = chat_color_codes.standard
	if string.sub(message, 1, #default_color) == default_color then
		message = string.sub(message, #default_color + 1)
	end

    -- Strip out prompt characters
    message = message:gsub(defines.auto_prompt_chars_pattern, '')
    message = message:gsub(defines.prompt_chars_pattern, '')
    -- for _, prompt_chars in ipairs(defines.PROMPT_CHARS) do
    --     local prompt_pos, _ = message:find(prompt_chars, -4, true)
    --     if prompt_pos ~= nil then
    --          message = message:sub(1, prompt_pos - 1)
    --     end
    -- end

    message = message:gsub(chat_color_codes.standard, '[BL_c1]') --color code 1 (black/reset)
    message = message:gsub(chat_color_codes.item, '[BL_c2]') --color code 2 (green/regular items)
    message = message:gsub(chat_color_codes.key_item, '[BL_c3]') --color code 3 (blue/key items)
    message = message:gsub(chat_color_codes.blue, '[BL_c4]') --color code 4 (blue/???)
    message = message:gsub(chat_color_codes.magenta, '[BL_c5]') --color code 5 (magenta/equipment?)
    message = message:gsub(chat_color_codes.cyan, '[BL_c6]') --color code 6 (cyan/???)
    message = message:gsub(chat_color_codes.yellow, '[BL_c7]') --color code 7 (yellow/???)
    message = message:gsub(chat_color_codes.orange, '[BL_c8]') --color code 8 (orange/RoE objectives?)
    message = message:gsub(chat_color_codes.emote, '') --cutscene emote color code (handled by the message type instead)

    message = message:gsub('^?([%w%.\'(<“])', '%1')
    message = message:gsub('%f[-]%-%-%f[^-]', '—') --replace -- with em dashes

    message = message:gsub('%[BL_c1]', '\\cr')
    message = message:gsub('%[BL_c2]', '\\cs('..ui._type.items..')')
    message = message:gsub('%[BL_c3]', '\\cs('..ui._type.keyitems..')')
    message = message:gsub('%[BL_c4]', '\\cs('..ui._type.keyitems..')')
    message = message:gsub('%[BL_c5]', '\\cs('..ui._type.gear..')')
    message = message:gsub('%[BL_c6]', '\\cs(0,159,173)')
    message = message:gsub('%[BL_c7]', '\\cs(156,149,19)')
    message = message:gsub('%[BL_c8]', '\\cs('..ui._type.roe..')')
    --TODO: theme settings for these element colors
    message = message:gsub('%[BL_Fire]', '\\cs(255,0,0)Fire \\cr')
    message = message:gsub('%[BL_Ice]', '\\cs(0,255,255)Ice \\cr')
    message = message:gsub('%[BL_Wind]', '\\cs(0,255,0)Wind \\cr')
    message = message:gsub('%[BL_Earth]', '\\cs(153,76,0)Earth \\cr')
    message = message:gsub('%[BL_Lightning]', '\\cs(127,0,255)Lightning \\cr')
    message = message:gsub('%[BL_Water]', '\\cs(0,76,153)Water \\cr')
    message = message:gsub('%[BL_Light]', '\\cs(224,224,224)Light \\cr')
    message = message:gsub('%[BL_Dark]', '\\cs(82,82,82)Dark \\cr')
    -- Mid message line breaks
    message = message:gsub(string.char(0x07), '\n')


    if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'codes end: ' .. parse_codes(message:sub(-4))) end
	if S{'message', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Final: ' .. encoding:UTF8_To_ShiftJIS(message)) end


    if not ui:set_character(npc_name) then
		ui:set_type(mode)
	end
	ui:set_message(message:trimex())
	balloon.open(timed)

	return result
end

balloon.convert_shiftjis_to_utf8 = function(str)
    str = balloon.sub_chars_pre_utf8(str)
	str = encoding:ShiftJIS_To_UTF8(str)
    str = balloon.sub_chars_post_utf8(str)
    return str
end

balloon.sub_chars_pre_utf8 = function(str)
	local new_str = str
	if S{'chars', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Pre-charsub pre-shift: ' .. new_str) end

	new_str = string.gsub(new_str, string.char(0x81, 0x40), '    ') -- tab
	new_str = string.gsub(new_str, string.char(0x81, 0xF4), '[BL_note]') -- musical note
	new_str = string.gsub(new_str, string.char(0x81, 0x99), '[BL_bstar]') -- empty star
	new_str = string.gsub(new_str, string.char(0x81, 0x9A), '[BL_wstar]') -- full star
	new_str = string.gsub(new_str, string.char(0x81, 0x60), '[BL_wave]') -- wide tilde
	new_str = string.gsub(new_str, string.char(0x87, 0xB2), '[BL_cldquote]') -- centered left double quote
	new_str = string.gsub(new_str, string.char(0x87, 0xB3), '[BL_crdquote]') -- centered right double quote
	new_str = string.gsub(new_str, string.char(0x88, 0x69), '[BL_e_acute]') -- acute accented e

	-- element symbols
	new_str = string.gsub(new_str, string.char(0xEF,0x1F), '[BL_Fire]')
	new_str = string.gsub(new_str, string.char(0xEF,0x20), '[BL_Ice]')
	new_str = string.gsub(new_str, string.char(0xEF,0x21), '[BL_Wind]')
	new_str = string.gsub(new_str, string.char(0xEF,0x22), '[BL_Earth]')
	new_str = string.gsub(new_str, string.char(0xEF,0x23), '[BL_Lightning]')
	-- extra 0x25 in these two to escape the characters
	new_str = string.gsub(new_str, string.char(0xEF,0x25,0x24), '[BL_Water]')
	new_str = string.gsub(new_str, string.char(0xEF,0x25,0x25), '[BL_Light]')
	new_str = string.gsub(new_str, string.char(0xEF,0x26), '[BL_Dark]')

	if S{'chars', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Post-charsub pre-shift: ' .. new_str) end
	return new_str
end

balloon.sub_chars_post_utf8 = function(str)
	local new_str = str
	if S{'chars', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Pre-charsub post-shift: ' .. new_str) end

	new_str = string.gsub(new_str, '%[BL_note]', '♪')
	new_str = string.gsub(new_str, '%[BL_bstar]', '☆')
	new_str = string.gsub(new_str, '%[BL_wstar]', '★')
	new_str = string.gsub(new_str, '%[BL_wave]', '~')
	new_str = string.gsub(new_str, '%[BL_cldquote]', '“')
	new_str = string.gsub(new_str, '%[BL_crdquote]', '”')
	new_str = string.gsub(new_str, '%[BL_e_acute]', 'é')

	if S{'chars', 'all'}[balloon.debug] then LogManager:Log(5, 'Balloon', 'Post-charsub post-shift: ' .. new_str) end
	return new_str
end

local function print_help(isError)
    -- Print the help header..
    if (isError) then
        print(chat.header(addon.name):append(chat.error('Invalid command syntax for command: ')):append(chat.success('/' .. addon.name)))
    else
        print(chat.header(addon.name):append(chat.message('Available commands:')))
    end

    local cmds = T{
        { '/balloon help', 'Displays this help information.' },
        { '/balloon 0', 'Hiding balloon & displaying log.' },
        { '/balloon 1', 'Show balloon & hide log.' },
        { '/balloon 2', 'Show balloon & displaying log.' },
        { '/balloon reset', 'Reset to default settings.' },
        { '/balloon reset pos', 'Reset the balloon position.' },
        { '/balloon theme <theme>', 'Loads the specified theme.' },
        { '/balloon scale <scale>', 'Scales the size of the balloon by a decimal (eg: 1.5).' },
        { '/balloon delay <seconds>', 'Delay before closing promptless balloons.' },
        { '/balloon speed <chars per second>', 'Speed that text is displayed, in characters per second.' },
        { '/balloon portrait', 'Toggle the display of character portraits, if the theme has settings for them.' },
        { '/balloon move_closes', 'Toggle balloon auto-close on player movement.' },
        { '/balloon test <name> <lang> <mode>', 'Display a test bubble. Lang: - (auto), en or ja. Mode: 1 (dialogue), 2 (system). "/balloon test" to see the list of available tests.' },
    }

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])))
    end)
end

ashita.events.register('command', 'balloon_command_cb', function(e)
    -- Parse the command arguments..
    local args = e.command:args()
    if (#args == 0 or (args[1] ~= '/bl' and args[1] ~= '/balloon')) then
        return
    end

    -- Block all related commands..
    e.blocked = true

    -- Handle: /balloon help
    if (#args == 2 and args[2]:any('help')) then
        print_help(false)
        return
    end

    -- Handle: /balloon [0,1,2]
    if (#args == 2 and args[2]:any('0', '1', '2')) then
        balloon.settings.display_mode = tonumber(args[2])
        local mode_desc = {
            'Hiding balloon & displaying log.',
            'Show balloon & hide log.',
            'Show balloon & displaying log.',
        }
        print(chat.header(addon.name):append(chat.message('Display mode changed: ')):append(chat.success(mode_desc[balloon.settings.display_mode + 1])))
        settings.save()
        return
    end

    -- Handle: /balloon reset
    if (#args >= 2 and args[2]:any('reset')) then
        if #args >= 3 and args[3]:any('pos', 'position') then
            print(chat.header(addon.name):append(chat.message('Resetting position')))
            balloon.settings.position.x = default_settings.position.x
            balloon.settings.position.y = default_settings.position.y
            settings.save()
            ui:position(balloon.settings.position.x, balloon.settings.position.y)
        else
            settings.reset()
        end
        return
    end

    -- Handle: /balloon theme
    if (#args >= 2 and args[2]:any('theme')) then
        if #args > 2 then
            local old_theme = balloon.settings.theme
            local old_theme_options = balloon.theme_options

            balloon.settings.theme = args[3]

            balloon.load_theme()
            if balloon.theme_options ~= nil then
                print(chat.header(addon.name):append(chat.message('Theme changed: ')):append(chat.success(balloon.settings.theme)))
            else
                -- Restore old settings
                balloon.theme_options = old_theme_options
                balloon.settings.theme = old_theme
            end

            settings.save()
        else
            print(chat.header(addon.name):append(chat.message('Theme: ')):append(chat.success(balloon.settings.theme)))
        end
        return
    end

    -- Handle numerical options
    -- Handle: /balloon scale
    -- Handle: /balloon delay
    -- Handle: /balloon speed
    if (#args >= 2 and args[2]:any('scale', 'delay', 'speed')) then
        local setting_key_alias = {
            delay = 'no_prompt_close_delay',
            speed = 'text_speed'
        }
        local setting_names = {
            no_prompt_close_delay = 'Promptless close delay',
            text_speed = 'Text speed',
            scale = 'Scale',
        }
        local setting_fmts = {
            no_prompt_close_delay = '%d',
            text_speed = '%d',
            scale = '%.2f',
        }
        local setting_key = setting_key_alias[args[2]] or args[2]
        local setting_name = setting_names[setting_key] or args[2]
        local setting_fmt = setting_fmts[setting_key] or args[2]

		if #args > 2 then
            local old_val = balloon.settings[setting_key]
			balloon.settings[setting_key] = tonumber(args[3])

            -- Some additional logic we need to run depending on the setting change
            if setting_key == 'scale' then
                ui:scale(balloon.settings.scale, balloon.settings.position)
            elseif setting_key == 'text_speed' then
                ui:text_speed(balloon.settings.text_speed)
            end

            print(chat.header(addon.name):append(chat.message('%s changed: '):format(setting_name)):append(chat.success('from ' .. setting_fmt .. ' to ' .. setting_fmt):format(old_val, balloon.settings[setting_key])))
            settings.save()
		else
			print(chat.header(addon.name):append(chat.message('%s: '):format(setting_name)):append(chat.success(setting_fmt):format(balloon.settings[setting_key])))
		end
        return
    end

    -- Handle toggle options
    -- Handle: /balloon portrait
    -- Handle: /balloon move_closes
    if (#args == 2 and args[2]:any('portrait', 'portraits', 'move_closes', 'move_close')) then
        local setting_key_alias = {
            portrait = 'portraits',
            move_closes = 'move_close',
        }
        local setting_names = {
            portraits = 'Display portraits',
            move_close = 'Close balloons on player movement',
        }
        local setting_key = setting_key_alias[args[2]] or args[2]
        local setting_name = setting_names[setting_key] or args[2]

        local old_val = balloon.settings[setting_key]
        balloon.settings[setting_key] = not old_val

        -- Some additional logic we need to run depending on the setting change
        if setting_key == 'portraits' then
            balloon.load_theme()
        end

        print(chat.header(addon.name):append(chat.message('%s changed: '):format(setting_name)):append(chat.success(balloon.settings[setting_key] and 'on' or 'off')))
        settings.save()
        return
    end

    -- Handle: /balloon test
    if (#args >= 2 and args[2]:any('test')) then
        local test_name = args[3]

        if test_name == nil then
            local test_names = T{}
            for k, _ in pairs(tests) do
                table.insert(test_names, k)
            end
            print(chat.header(addon.name):append('Available tests: '):append(chat.success(test_names:join(', '))))
            return
        end

        local lang = args[4] or balloon.lang_code
        if lang == '-' then
            lang = balloon.lang_code
        end
        local lang_map = {
            en = 2,
            ja = 3,
        }
        local lang_index = lang_map[lang] or 2

        local test_entry = tests[test_name]
        if test_entry == nil then
            print(chat.header(addon.name):append(chat.error('Invalid test: %s'):format(test_name)))
            return
        end

        local npc_name = test_entry[1]
        print(chat.header(addon.name):append(chat.message('Test: %s (%s)'):format(test_name, lang)))
        local message = test_entry[lang_index]
        local mode = (args[5] == '2' or npc_name == '') and chat_modes.system or chat_modes.message
        local message_prefix = npc_name ~= '' and (npc_name .. ' : ') or ''
        balloon.process_balloon(message_prefix .. message, mode)
        return
    end

    -- Unhandled: Print help information..
    print_help(true)
end)

ashita.events.register('load', 'balloon_load', function()
    balloon.settings = settings.load(default_settings)
    balloon.last_frame_time = os.clock()

    balloon.initialize()

    -- Register for settings updates
    settings.register('settings', 'balloon_settings_update', function(s)
        if (s ~= nil) then
            balloon.settings = s
            balloon.initialize(s)
        end
    end)
end)

ashita.events.register('unload', 'balloon_unload', function()
    ui:destroy()
end)

ashita.events.register('packet_in', 'balloon_packet_in', function(e)
    if balloon.theme_options == nil then
        return
    end

	-- Check if player has left a conversation
    if e.id == defines.packets.inc.mog_menu then
        balloon.in_mog_menu = true
    elseif e.id == defines.packets.inc.zone_out then
		balloon.close()
    elseif e.id == defines.packets.inc.leave_conversation then
        if balloon.in_mog_menu then
            balloon.in_mog_menu = false
            return
        end
        local type = struct.unpack('b', e.data_modified, 0x04 + 1)
        LogManager:Log(5, 'Balloon', 'packets.inc.leave_conversation - type: ' .. tostring(type))
        if tonumber(type) == 0 then
            if balloon.debug_closing then print('Closing from leave conversation: ' .. type) end
            balloon.close()
        end
	end
end)

ashita.events.register('packet_out', 'balloon_packet_out', function (e)
    if balloon.theme_options == nil then
        return
    end

    -- Check if player has left a conversation
    -- Since this is outgoing, this comes sooner than the incoming LEAVE_CONVERSATION_PACKET
	if e.id == defines.packets.out.dialogue_option then
        local in_menu = struct.unpack('H', e.data_modified, 0x0E + 1)
        local option_index = struct.unpack('H', e.data_modified, 0x08 + 1)

        if in_menu == 1 then
            balloon.in_menu = true
        elseif option_index == 0 or option_index == 2 then --if option_index ~= 2 then -- 2 = selected a home point warp
            if balloon.debug_closing then print('Closing from dialogue option') end
            balloon.close()
        end

        LogManager:Log(5, 'Balloon', 'packets.out.dialogue_option - option_index: ' .. tostring(option_index) .. ', in_menu: ' .. tostring(in_menu))
	end

    if e.id == defines.packets.out.homepoint_map then
        -- User is viewing home point map
        balloon.close()
        -- We're still in the menu
        balloon.in_menu = true
    end
end)

ashita.events.register('text_in', 'balloon_text_in', function(e)
    if balloon.theme_options == nil then
        return
    end
    -- Ignore text in from Ashita addons/plugins
    if e.injected then
        return
    end

    if not balloon.processing_message then
        balloon.processing_message = true

        balloon.process_incoming_message(e)

        balloon.processing_message = false
    end
end)

ashita.events.register('d3d_present', 'balloon_d3d_present', function()
    -- Calculate delta time for animations
    local frame_time = os.clock()
    local delta_time = frame_time - balloon.last_frame_time
    balloon.last_frame_time = frame_time

    if balloon.theme_options == nil then
        return
    end

    -- Don't display unless we have a player entity and we're not zoning
    local player = AshitaCore:GetMemoryManager():GetPlayer()
    local player_ent = GetPlayerEntity()
    if (player == nil or player.isZoning or player_ent == nil) then
		return
	end

    -- Handle movement closes balloon
    balloon.handle_player_movement(player_ent)

    if not ui:hidden() then
        ui:render(delta_time)
    end
end)

ashita.events.register('mouse', 'balloon_mouse', function (e)
    if e.message == defines.MOUSE_DOWN then
        if ui:hidden() then
            return
        end

        local ui_x, ui_y = ui:position()
        local w, h = ui:window_size()
        local mouse_x, mouse_y = e.x, e.y

        -- Mouse click inside balloon?
        if mouse_x >= ui_x and mouse_x <= ui_x + w and
           mouse_y >= ui_y and mouse_y <= ui_y + h then
            balloon.drag_offset = {
                ui_x - mouse_x,
                ui_y - mouse_y,
            }
            e.blocked = true
        end
    elseif balloon.drag_offset ~= nil then
        e.blocked = true

        local new_position = {
            e.x + balloon.drag_offset[1],
            e.y + balloon.drag_offset[2],
        }

        if e.message == defines.MOUSE_UP or ui:hidden() then
            ui:position(new_position[1], new_position[2], true)

            -- Convert to center anchor for saving to settings
            local w, h = ui:window_size()
            balloon.settings.position.x = new_position[1] + w / 2
            balloon.settings.position.y = new_position[2] + h / 2
            settings.save()

            balloon.drag_offset = nil
        else
            ui:position(new_position[1], new_position[2], true)
        end
    end
end)

ashita.events.register('key_data', 'balloon_key_data', function(e)
    if is_chat_open() then
        return
    end

    -- DirectInput key codes http://www.flint.jp/misc/?q=dik
    if e.down and (e.key == 0x01 or e.key == 0x1C) then
        if not ui:hidden() then
            if balloon.debug_closing then print('Closing from enter key') end
            balloon.close()
        end
    end
end)

ashita.events.register('dinput_button', 'balloon_dinput_button', function(e)
    if is_chat_open() then
        return
    end

    if defines.DINPUT_CONTROLLER_DISMISS[e.button] ~= nil and e.state == 128 then
        if not ui:hidden() then
            if balloon.debug_closing then print('Closing from dinput') end
            balloon.close()
        end
    end
end)

ashita.events.register('xinput_button', 'balloon_xinput_button', function(e)
    if is_chat_open() then
        return
    end

    if defines.XINPUT_CONTROLLER_DISMISS[e.button] ~= nil and e.state == 1 then
        if not ui:hidden() then
            if balloon.debug_closing then print('Closing from xinput') end
            balloon.close()
        end
    end
end)
