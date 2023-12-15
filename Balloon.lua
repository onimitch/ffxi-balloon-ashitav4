addon.name      = 'Balloon'
addon.author    = 'Originally by Hando, English support added by Yuki & Kenshi, themes added by Ghosty, ported to Ashita v4 by onimitch.'
addon.version   = '4.0'
addon.desc      = 'Displays NPC chat logs in a UI Balloon, similar to FFXIV.'
addon.link      = 'https://github.com/onimitch/ffxi-balloon-ashitav4'

-- Ashita libs
require('common')
local chat = require('chat')
settings = require('settings')
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

-- local ENTER_KEY = 28
-- local SCROLL_LOCK_KEY = 70

local balloon = {}
balloon.debug = 'off'
balloon.moving = false
balloon.old_x = "0"
balloon.old_y = "0"
-- balloon.keydown = false
-- balloon.mouse_on = false
balloon.prev_path = nil
balloon.waiting_to_close = false
balloon.close_timer = 0
balloon.last_text = ''
balloon.last_mode = 0
balloon.movement_thread = nil
balloon.processing_message = false
balloon.lang_code = 'en'
balloon.settings = {}
balloon.last_frame_time = 0
balloon.theme_options = nil

-------------------------------------------------------------------------------

balloon.initialize = function()
    -- Get game language
    local lang = AshitaCore:GetConfigurationManager():GetInt32('boot', 'ashita.language', 'playonline', 2)
    balloon.lang_code = 'en'
    if lang == 1 then
        balloon.lang_code = 'ja'
    end

	balloon.apply_theme()

    -- -- TODO TIMERS
	-- --スレッド開始 (Thread start)
	-- if settings.move_close then
	-- 	balloon.movement_thread = moving_check:schedule(0)
	-- end

	if balloon.theme_options ~= nil then
        print(chat.header(addon.name):append(chat.message('Theme "%s", language: %s'):format(balloon.settings.theme, balloon.lang_code)))
    end
end

balloon.apply_theme = function()
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
    if balloon.close_timer >= 0 then
        balloon.close_timer = math.max(0, balloon.close_timer - 1)
        ui.timer_text:text(balloon.close_timer..'')
    end

    if balloon.close_timer <= 0 then
        balloon.close()
    else
        ashita.tasks.once(1, balloon.update_timer)
    end
end

balloon.open = function(timed)
	if timed then
		balloon.close_timer = balloon.settings.no_prompt_close_delay
		ui.timer_text:text(''..balloon.close_timer)
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
end

-- function moving_check()
--     local entity = AshitaCore:GetMemoryManager():GetEntity()
--     local party = AshitaCore:GetMemoryManager():GetParty()
--     local player = AshitaCore:GetMemoryManager():GetPlayer()
--     local index = party:GetMemberTargetIndex(0)
-- 	if player == nil then return end

-- 	local x,y

-- 	while true do
-- 		-- me = windower.ffxi.get_mob_by_id(p.id)
-- 		-- if me ~= nil then
--         x = string.format("%6d",entity:GetLocalPositionX(index))
--         y = string.format("%6d",entity:GetLocalPositionY(index))
--         --if x ~= old_x and y ~= old_y then
--         if (tonumber(x) < tonumber(balloon.old_x) - 1 or tonumber(x) > tonumber(balloon.old_x) + 1) or (tonumber(y) < tonumber(balloon.old_y) - 1 or tonumber(y) > tonumber(balloon.old_y) + 1) then
--             balloon.moving = true
--             balloon.old_y = y
--             balloon.old_x = x
--         else
--             balloon.moving = false
--         end
-- 		-- end
-- 		--wait
-- 		balloon.waiting_to_close = true
-- 		coroutine.sleep(balloon.settings.no_prompt_close_delay)
-- 		if balloon.moving and balloon.settings.move_close and balloon.waiting_to_close then
-- 			close()
-- 		end
-- 	end

-- end

balloon.process_incoming_message = function(e)
    -- Obtain the chat mode..
    local mode = bit.band(e.mode_modified,  0x000000FF);

	-- print debug info
	if S{'mode', 'all'}[balloon.debug] then print("Mode: " .. mode .. " Text: " .. e.message) end

	-- skip text modes that aren't NPC speech
    if not S{chat_modes.message, chat_modes.system, chat_modes.timed_battle, chat_modes.timed_message}[mode] then
        if S{'all'}[balloon.debug] then print(("Not accepted mode: %d"):format(mode)) end
        return
    end

	-- blank prompt line that auto-continues itself,
	-- usually used to clear a space for a scene change?
	if e.message:endswith(defines.AUTO_PROMPT_CHARS) then
		balloon.close()
		return
	end

	-- print debug info
	-- if S{'codes', 'all'}[balloon.debug] then print("codes: " .. codes(e.message)) end

	if balloon.settings.display_mode >= 1 then
		e.message_modified = balloon.process_balloon(e.message, mode)
    end
end

balloon.process_balloon = function(npc_text, mode)
	balloon.last_text = npc_text
	balloon.last_mode = mode

	-- detect whether messages have a prompt button
	local timed = true
	if S{chat_modes.message, chat_modes.system}[mode] and npc_text:sub(-#defines.PROMPT_CHARS) == defines.PROMPT_CHARS then
		timed = false
	end

	-- 発言者名の抽出 (Speaker name extraction)
	local start,_end = npc_text:find(".- : ")
	local npc_prefix = ""
	if start ~= nil then
		if _end < 32 and start > 0 then 
            npc_prefix = npc_text:sub(start, _end)
        end
	end
	local npc_name = npc_prefix:sub(0, #npc_prefix-2)
	npc_name = string.trimex(npc_name)

	if not ui:set_character(npc_name) then
		ui:set_type(mode)
	end

    -- pass through the original message for the log
    local result = npc_text

	-- mode 1, blank log lines and visible balloon
	if balloon.settings.display_mode == 1 then
        -- Check if message contains prompt chars
        local end_of_text_pos = #npc_text - 1
        for _, prompt_chars in ipairs(defines.STRIP_PROMPT_CHARS) do
            local prompt_pos, _ = npc_text:find(prompt_chars, -4, true)
            if prompt_pos ~= nil then
                end_of_text_pos = prompt_pos
                break
            end
        end
        result = npc_prefix
        if npc_prefix ~= "" then
            result = result .. '...'
        end
        -- Preserve prompt chars
        result = result .. npc_text:sub(end_of_text_pos, #npc_text)

		-- if npc_prefix == "" then
		-- 	-- result = "" .. "\n"
        --     result = npc_text:sub(#npc_text-1, #npc_text)
		-- else
        --     -- Preserve prompt chars
		-- 	result = npc_prefix .. '...' .. npc_text:sub(#npc_text-1, #npc_text)
		-- end
	end

    if S{'chars', 'all'}[balloon.debug] then print("npc_text: " .. npc_text) end
    if S{'codes', 'all'}[balloon.debug] then print("codes before: " .. codes(npc_text:sub(-4))) end

	-- 発言 (Remark)
	local mes = SubCharactersPreShift(npc_text)
	mes = encoding:ShiftJIS_To_UTF8(mes)
    mes = SubCharactersPostShift(mes)

	-- strip the NPC name from the start of the message
	if npc_prefix ~= "" then
		mes = mes:gsub(npc_prefix:gsub("-","--"),"") --タルタル等対応 (Correspondence such as tartar)
	end

	if S{'process', 'all'}[balloon.debug] then print("Pre-process: " .. mes) end
	if S{'codes', 'all'}[balloon.debug] then print("codes after: " .. codes(mes:sub(-4))) end

	-- strip the default color code from the start of messages,
	-- it causes the first part of the message to get cut off somehow
	local default_color = chat_color_codes.standard
	if string.sub(mes, 1, #default_color) == default_color then
		mes = string.sub(mes, #default_color + 1)
	end

	-- split by newlines
	local message_lines = mes:split(string.char(0x07))

	local message = ""
	for k,v in ipairs(message_lines) do
        -- Strip out everything after a prompt character
        for _, prompt_chars in ipairs(defines.STRIP_PROMPT_CHARS) do
            local prompt_pos, _ = v:find(prompt_chars, -4, true)
            if prompt_pos ~= nil then
                v = v:sub(1, prompt_pos - 1)
            end
        end

		v = string.gsub(v, chat_color_codes.standard, "[BL_c1]") --color code 1 (black/reset)
		v = string.gsub(v, chat_color_codes.item, "[BL_c2]") --color code 2 (green/regular items)
		v = string.gsub(v, chat_color_codes.key_item, "[BL_c3]") --color code 3 (blue/key items)
		v = string.gsub(v, chat_color_codes.blue, "[BL_c4]") --color code 4 (blue/???)
		v = string.gsub(v, chat_color_codes.magenta, "[BL_c5]") --color code 5 (magenta/equipment?)
		v = string.gsub(v, chat_color_codes.cyan, "[BL_c6]") --color code 6 (cyan/???)
		v = string.gsub(v, chat_color_codes.yellow, "[BL_c7]") --color code 7 (yellow/???)
		v = string.gsub(v, chat_color_codes.orange, "[BL_c8]") --color code 8 (orange/RoE objectives?)
		v = string.gsub(v, chat_color_codes.cutscene_emote, "") --cutscene emote color code (handled by the message type instead)
        
		v = string.gsub(v, "^?([%w%.'(<“])", "%1")
		v = string.gsub(v, '(%w)(%.%.%.+)([%w“])', "%1%2 %3") --add a space after elipses to allow better line splitting
		v = string.gsub(v, '([%w”])%-%-([%w%p])', "%1-- %2") --same for double dashes

		v = string.gsub(v, "%[BL_c1]", "\\cr")
		v = string.gsub(v, "%[BL_c2]", "\\cs("..ui._type.items..")")
		v = string.gsub(v, "%[BL_c3]", "\\cs("..ui._type.keyitems..")")
		v = string.gsub(v, "%[BL_c4]", "\\cs("..ui._type.keyitems..")")
		v = string.gsub(v, "%[BL_c5]", "\\cs("..ui._type.gear..")")
		v = string.gsub(v, "%[BL_c6]", "\\cs(0,159,173)")
		v = string.gsub(v, "%[BL_c7]", "\\cs(156,149,19)")
		v = string.gsub(v, "%[BL_c8]", "\\cs("..ui._type.roe..")")
		--TODO: theme settings for these element colors
		v = string.gsub(v, "%[BL_Fire]", "\\cs(255,0,0)Fire \\cr")
		v = string.gsub(v, "%[BL_Ice]", "\\cs(0,255,255)Ice \\cr")
		v = string.gsub(v, "%[BL_Wind]", "\\cs(0,255,0)Wind \\cr")
		v = string.gsub(v, "%[BL_Earth]", "\\cs(153,76,0)Earth \\cr")
		v = string.gsub(v, "%[BL_Lightning]", "\\cs(127,0,255)Lightning \\cr")
		v = string.gsub(v, "%[BL_Water]", "\\cs(0,76,153)Water \\cr")
		v = string.gsub(v, "%[BL_Light]", "\\cs(224,224,224)Light \\cr")
		v = string.gsub(v, "%[BL_Dark]", "\\cs(82,82,82)Dark \\cr")

		message = message .. string.format('\n%s', v)
	end

    if S{'codes', 'all'}[balloon.debug] then print("codes end: " .. codes(message:sub(-4))) end
	if S{'process', 'all'}[balloon.debug] then print("Final: " .. message) end

	ui:set_message(message:trimex())
	balloon.open(timed)

	return result
end

-- parses a string into char[hex bytecode]
function codes(str)
	return (str:gsub('.', function (c)
		return string.format('[%02X]', string.byte(c))
	end))
end

function SubCharactersPreShift(str)
	local new_str = str
	if S{'chars', 'all'}[balloon.debug] then print("Pre-charsub pre-shift: " .. new_str) end
	new_str = string.gsub(new_str, string.char(0x81, 0x40), '    ') -- tab
	new_str = string.gsub(new_str, string.char(0x81, 0xF4), '[BL_note]') -- musical note
	new_str = string.gsub(new_str, string.char(0x81, 0x99), '[BL_bstar]') -- empty star
	new_str = string.gsub(new_str, string.char(0x81, 0x9A), '[BL_wstar]') -- full star
	new_str = string.gsub(new_str, string.char(0x81, 0x60), '[BL_wave]') -- wide tilde
	new_str = string.gsub(new_str, string.char(0x87, 0xB2), '[BL_cldquote]') -- centered left double quote
	new_str = string.gsub(new_str, string.char(0x87, 0xB3), '[BL_crdquote]') -- centered right double quote
	new_str = string.gsub(new_str, string.char(0x88, 0x69), '[BL_e_acute]') -- acute accented e

	-- element symbols
	new_str = string.gsub(new_str, string.char(0xEF,0x1F), "[BL_Fire]")
	new_str = string.gsub(new_str, string.char(0xEF,0x20), "[BL_Ice]")
	new_str = string.gsub(new_str, string.char(0xEF,0x21), "[BL_Wind]")
	new_str = string.gsub(new_str, string.char(0xEF,0x22), "[BL_Earth]")
	new_str = string.gsub(new_str, string.char(0xEF,0x23), "[BL_Lightning]")
	-- extra 0x25 in these two to escape the characters
	new_str = string.gsub(new_str, string.char(0xEF,0x25,0x24), "[BL_Water]")
	new_str = string.gsub(new_str, string.char(0xEF,0x25,0x25), "[BL_Light]")
	new_str = string.gsub(new_str, string.char(0xEF,0x26), "[BL_Dark]")
	if S{'chars', 'all'}[balloon.debug] then print("Post-charsub pre-shift: " .. new_str) end
	return new_str
end

function SubCharactersPostShift(str)
	local new_str = str
	if S{'chars', 'all'}[balloon.debug] then print("Pre-charsub post-shift: " .. new_str) end
	new_str = string.gsub(new_str, '%[BL_note]', '♪')
	new_str = string.gsub(new_str, '%[BL_bstar]', '☆')
	new_str = string.gsub(new_str, '%[BL_wstar]', '★')
	new_str = string.gsub(new_str, '%[BL_wave]', '~')
	new_str = string.gsub(new_str, '%[BL_cldquote]', '“')
	new_str = string.gsub(new_str, '%[BL_crdquote]', '”')
	new_str = string.gsub(new_str, '%[BL_e_acute]', 'é')
	if S{'chars', 'all'}[balloon.debug] then print("Post-charsub post-shift: " .. new_str) end
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
        { '/balloon theme <theme>', 'Loads the specified theme.' },
        { '/balloon scale <scale>', 'Scales the size of the balloon by a decimal (eg: 1.5).' },
        { '/balloon delay <seconds>', 'Delay before closing promptless balloons.' },
        { '/balloon text_speed <chars>', 'Speed that text is displayed, in characters per frame.' },
        { '/balloon portrait', 'Toggle the display of character portraits, if the theme has settings for them.' },
        { '/balloon move_closes', 'Toggle balloon auto-close on player movement.' },
        { '/balloon test <name> <lang> <mode>', 'Display a test bubble. Lang: - (auto), en or ja. Mode: 1 (dialogue), 2 (system). \"/balloon test\" to see the list of available tests.' },
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
    e.blocked = true;

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
    if (#args == 2 and args[2]:any('reset')) then
        settings.reset()
        return
    end

    -- Handle: /balloon theme
    if (#args >= 2 and args[2]:any('theme')) then
        if #args > 2 then
            local old_theme = balloon.settings.theme
            local old_theme_options = balloon.theme_options
            
            balloon.settings.theme = args[3]

            balloon.apply_theme()
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
    if (#args == 2 and args[2]:any('portrait', 'move_closes')) then
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

        if #args > 2 then
            local old_val = balloon.settings[setting_key]
			balloon.settings[setting_key] = not balloon.settings[setting_key]

            -- Some additional logic we need to run depending on the setting change
            if setting_key == 'portraits' then
                balloon.apply_theme()
            end

            print(chat.header(addon.name):append(chat.message('%s changed: '):format(setting_name)):append(chat.success(balloon.settings[setting_key] and 'on' or 'off')))
            settings.save()
		else
			print(chat.header(addon.name):append(chat.message('%s: '):format(setting_name)):append(chat.success(balloon.settings[setting_key] and 'on' or 'off')))
		end
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
            print(chat.header(addon.name):append("Available tests: "):append(chat.success(test_names:join(', '))))
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
        local message = test_entry[lang_index]
        local mode = args[5] == '2' and chat_modes.system or chat_modes.message
        balloon.process_balloon(npc_name .. ' : ' .. message, mode)
        return
    end

    -- Unhandled: Print help information..
    print_help(true)
end)

ashita.events.register('load', 'balloon_load', function()
    balloon.settings = settings.load(default_settings)
    balloon.last_frame_time = os.clock()

    balloon.initialize()

    -- Register for future settings updates
    settings.register('settings', 'balloon_settings_update', function()
        if (s ~= nil) then
            balloon.settings = s
        end
    
        settings.save()
        balloon.initialize()
    end)
end)

ashita.events.register('unload', 'balloon_unload', function()
    -- print("balloon.unload")
    ui:destroy()
end)

ashita.events.register('packet_in', 'balloon_packet_in', function(e)
    if balloon.theme_options == nil then
        return
    end

	-- if S{'chunk', 'all'}[balloon.debug] then print("Chunk: " .. string.format('0x%02X', e.id) .. " original: " .. e.data_modified) end

	--会話中かの確認 (Check if you have left a conversation)
	if S{defines.LEAVE_CONVERSATION_PACKET, defines.ZONE_OUT_PACKET}[e.id] then
		balloon.close()
	end
end)

ashita.events.register('text_in', 'balloon_text_in', function(e)
    if balloon.theme_options == nil then
        return
    end

    if not balloon.processing_message then
        balloon.processing_message = true

        balloon.process_incoming_message(e)

        balloon.processing_message = false
    end
end)

ashita.events.register('d3d_present', 'balloon_d3d_present', function()
    if balloon.theme_options == nil then
        return
    end

    -- Calculate delta time for animations
    local frame_time = os.clock()
    local delta_time = frame_time - balloon.last_frame_time
    balloon.last_frame_time = frame_time

    if not ui:hidden() then
        ui:render(delta_time)
    end
end)

-- windower.register_event('keyboard',function(key_id,pressed,flags,blocked)
-- 	if windower.ffxi.get_info().chat_open or blocked then return end
-- 	if not ui:hidden() then
-- 		if key_id == ENTER_KEY and pressed and not balloon.keydown then
-- 			balloon.keydown = true
-- 			close()
-- 		end
-- 		if key_id == SCROLL_LOCK_KEY and pressed and not balloon.keydown then
-- 			balloon.keydown = true
-- 			if not ui:hidden() then
-- 				ui:hide()
-- 			else
-- 				ui:show()
-- 			end
-- 		end
-- 	end
-- 	if S{ENTER_KEY, SCROLL_LOCK_KEY}[key_id] and not pressed then balloon.keydown = false end
-- end)

-- windower.register_event("mouse",function(type,x,y,delta,blocked)
--     if not ui.message_background:hover(x, y) then return false end

-- 	-- press
-- 	if type == 1 then
-- 		balloon.mouse_on = true
-- 	end
-- 	-- release
-- 	if type == 2 then
-- 		balloon.mouse_on = false
-- 		config.save(settings)
-- 	end
-- 	if balloon.mouse_on == true then
-- 		update_position()
-- 	end
-- end)

-- function update_position()
-- 	settings.Position.X = ui.message_background:pos_x() + ui.message_background:width() / 2
-- 	settings.Position.Y = ui.message_background:pos_y() + ui.message_background:height() / 2

-- 	ui:position(settings.Position.X, settings.Position.Y)
-- end
