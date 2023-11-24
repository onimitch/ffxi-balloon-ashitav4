addon.name      = 'Balloon'
addon.author    = 'Originally by Hando, English support added by Yuki & Kenshi, themes added by Ghosty, ported to Ashita v4 by onimitch.'
addon.version   = '1.0'
addon.desc      = 'Displays NPC chat logs in a UI Balloon, similar to FF14.'
addon.link      = 'https://github.com/onimitch/ffxi-balloon-ashitav4'

-- Ashita libs
require('common')
local chat = require('chat')
settings = require('settings')
local encoding = require('gdifonts.encoding')

-- Windower ported luau libs
require('libs.luau')
chars = require('libs.chat.chars')
chars.cldquo = string.char(0x87, 0xB2)
chars.crdquo = string.char(0x87, 0xB3)
texts = require('libs.texts')
images = require('libs.images')

-- Balloon files
local default_settings = require('defaults')
local theme = require('theme')
local theme_options = {}
local ui = require('ui')
local tests = require('tests')


-- TODO

-- Cancel close timer on close()
-- Move close
-- Render color tags \cs and \cr

-- TIDY UP

-- Strip unused windower libs
-- Strip any other unused code
-- Strip out debug prints
-- Tidy up error prints


local MODE = {}
MODE.MESSAGE = 150
MODE.SYSTEM = 151
MODE.TIMED_MESSAGE = 144
MODE.TIMED_BATTLE = 142
MODE.CUTSCENE_EMOTE = 15

local ENTER_KEY = 28
local SCROLL_LOCK_KEY = 70

local ZONE_OUT_PACKET = 0x0B
local LEAVE_CONVERSATION_PACKET = 0x52

-- 0x31-0x33 and 0x37 all appear the same
local PROMPT_CHARS = string.char(0x7F,0x31)
-- the 0x01 in this is the number of seconds before the prompt continues itself
-- 0x34-0x36 seem to do the same thing
local AUTO_PROMPT_CHARS = string.char(0x7F,0x34,0x01)

local balloon = {}
balloon.debug = 'off'
balloon.moving = false
balloon.old_x = "0"
balloon.old_y = "0"
balloon.on = false
-- balloon.keydown = false
-- balloon.mouse_on = false
balloon.frame_count = 0
balloon.prev_path = nil
balloon.waiting_to_close = false
balloon.close_timer = 0
balloon.last_text = ''
balloon.last_mode = 0
balloon.movement_thread = nil
balloon.processing_message = false
balloon.lang_code = 'en'
balloon.settings = {}

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

	if theme_options ~= nil then
        print(chat.header(addon.name):append(chat.message('Loaded Theme "%s", %s'):format(balloon.settings.theme, balloon.lang_code)))
    end
end

balloon.apply_theme = function()
    -- Load the theme
    theme_options = theme.load(balloon.settings.theme, balloon.lang_code)
    if theme_options == nil then
        return
    end

    -- Load UI
	ui:load(balloon.settings, theme_options)

    -- Display balloon if we changed theme while open
	if balloon.on then
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

    print("balloon.open")

	ui:show(timed)

    if timed and not balloon.waiting_to_close then
        balloon.waiting_to_close = true
        ashita.tasks.once(1, balloon.update_timer)
    end
	balloon.on = true
end

balloon.close = function()
    if balloon.on then
        print("balloon.close")
    end
	ui:hide()

	balloon.on = false
    balloon.waiting_to_close = false
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
	if S{'codes', 'mode', 'all'}[balloon.debug] then print("Mode: " .. mode .. " Text: " .. e.message) end

	-- skip text modes that aren't NPC speech
    if not S{MODE.MESSAGE, MODE.SYSTEM, MODE.TIMED_BATTLE, MODE.TIMED_MESSAGE}[mode] then 
        if S{'codes', 'all'}[balloon.debug] then print(("Not accepted mode: %d"):format(mode)) end
        return 
    end

	-- blank prompt line that auto-continues itself,
	-- usually used to clear a space for a scene change?
	if e.message:endswith(AUTO_PROMPT_CHARS) then
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
	if S{MODE.MESSAGE, MODE.SYSTEM}[mode] and npc_text:sub(-#PROMPT_CHARS) == PROMPT_CHARS then
		timed = false
	end

	-- 発言者名の抽出 (Speaker name extraction)
	local start,_end = npc_text:find(".- : ")
	local npc_prefix = ""
	if start ~= nil then
		if _end < 32 and start > 0 then npc_prefix = npc_text:sub(start,_end) end
	end
	local npc_name = npc_prefix:sub(0,#npc_prefix-2)
	npc_name = string.trimex(npc_name)

	if not ui:set_character(npc_name) then
		ui:set_type(mode)
	end

	-- mode 1, blank log lines and visible balloon
	if balloon.settings.display_mode == 1 then
		if npc_prefix == "" then
			result = "" .. "\n"
		else
			result = npc_text:sub(#npc_text-1,#npc_text)
		end
	-- mode 2, visible log and balloon
	elseif balloon.settings.display_mode == 2 then
		-- pass through the original message for the log
		result = npc_text
	end

    if S{'chars', 'all'}[balloon.debug] then print("npc_text: " .. npc_text) end

	-- 発言 (Remark)
	local mes = SubCharactersPreShift(npc_text)
    -- if S{'chars', 'all'}[balloon.debug] then print("message length preshift: npc_text=" .. npc_text:len() .. ", after: " .. mes:len() .. ", type: " .. type(mes)) end

	mes = encoding:ShiftJIS_To_UTF8(mes)

    if S{'chars', 'all'}[balloon.debug] then print("message length: mes: " .. mes:len() .. ", source_length: " .. encoding_report.source_length .. ", wchar_Length: " .. encoding_report.wchar_Length .. ", char_length: " .. encoding_report.char_length) end

	mes = SubCharactersPostShift(mes)

	-- strip the NPC name from the start of the message
	if npc_prefix ~= "" then
		mes = mes:gsub(npc_prefix:gsub("-","--"),"") --タルタル等対応 (Correspondence such as tartar)
	end

	if S{'process', 'all'}[balloon.debug] then print("Pre-process: " .. mes) end
	if S{'codes', 'all'}[balloon.debug] then print("codes: " .. codes(mes)) end

	--strip the default color code from the start of messages,
	--it causes the first part of the message to get cut off somehow
	local default_color = string.char(0x1E,0x01)
	if string.sub(mes, 1, #default_color) == default_color then
		mes = string.sub(mes, #default_color + 1)
	end

	-- split by newlines
	local message_lines = split(mes, string.char(0x07))

	local message = ""
	for k,v in ipairs(message_lines) do
		v = string.gsub(v, string.char(0x1E,0x01), "[BL_c1]") --color code 1 (black/reset)
		v = string.gsub(v, string.char(0x1E,0x02), "[BL_c2]") --color code 2 (green/regular items)
		v = string.gsub(v, string.char(0x1E,0x03), "[BL_c3]") --color code 3 (blue/key items)
		v = string.gsub(v, string.char(0x1E,0x04), "[BL_c4]") --color code 4 (blue/???)
		v = string.gsub(v, string.char(0x1E,0x05), "[BL_c5]") --color code 5 (magenta/equipment?)
		v = string.gsub(v, string.char(0x1E,0x06), "[BL_c6]") --color code 6 (cyan/???)
		v = string.gsub(v, string.char(0x1E,0x07), "[BL_c7]") --color code 7 (yellow/???)
		v = string.gsub(v, string.char(0x1E,0x08), "[BL_c8]") --color code 8 (orange/RoE objectives?)
		v = string.gsub(v, string.char(0x1F,0x0F), "") --cutscene emote color code (handled by the message type instead)
		v = string.gsub(v, PROMPT_CHARS, "")
		-- these are the auto-prompt characters
		v = string.gsub(v, string.char(0x7F,0x34), "")
		v = string.gsub(v, string.char(0x7F,0x35), "")
		v = string.gsub(v, string.char(0x7F,0x36), "")
		-- these are often the timings for the auto-prompt
		v = string.gsub(v, string.char(0x01), "")
		v = string.gsub(v, string.char(0x02), "")
		v = string.gsub(v, string.char(0x03), "")
		v = string.gsub(v, string.char(0x04), "")
		v = string.gsub(v, string.char(0x05), "")
		v = string.gsub(v, string.char(0x06), "")
		v = string.gsub(v, "^?([%w%.'(<“])", "%1")
		v = string.gsub(v, '(%w)(%.%.%.+)([%w“])', "%1%2 %3") --add a space after elipses to allow better line splitting
		v = string.gsub(v, '([%w”])%-%-([%w%p])', "%1-- %2") --same for double dashes

        -- Disabled manually wrapping in favour of automatic wrapping of text via GDI font rendering
		-- v = ui:wrap_text(v)

        -- Disabled: This is causing empty spaces at start of lines??
		-- v = " " .. v

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
	if S{'process', 'all'}[balloon.debug] then print("Final: " .. message) end

	ui:set_message(message:trimex())
	balloon.open(timed)

	return result
end

-- parses a string into char[hex bytecode]
function codes(str)
	return (str:gsub('.', function (c)
		return string.format('%s[%02X]', c, string.byte(c))
	end))
end

function SubCharactersPreShift(str)
	local new_str = str
	if S{'chars', 'all'}[balloon.debug] then print("Pre-charsub pre-shift: " .. new_str) end
	new_str = string.gsub(new_str, string.char(0x81, 0x40), '    ') -- tab
	new_str = string.gsub(new_str, string.char(0x81, 0xF4), '[BL_note]') -- musical note
	new_str = string.gsub(new_str, chars.bstar, '[BL_bstar]') -- empty star
	new_str = string.gsub(new_str, chars.wstar, '[BL_wstar]') -- full star
	new_str = string.gsub(new_str, chars.wave, '[BL_wave]') -- wide tilde
	new_str = string.gsub(new_str, chars.cldquo, '[BL_cldquote]') -- centered left double quote
	new_str = string.gsub(new_str, chars.crdquo, '[BL_crdquote]') -- centered right double quote
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

function split(str, delim)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end

    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local lastPos
    for part, pos in string.gmatch(str, pat) do
        table.insert(result, part)
        lastPos = pos
    end
    table.insert(result, string.sub(str, lastPos))
    return result
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
        { '/balloon animate', 'Toggle the advancement prompt indicator bouncing.' },
        { '/balloon portrait', 'Toggle the display of character portraits, if the theme has settings for them.' },
        { '/balloon move_closes', 'Toggle balloon auto-close on player movement.' },
    }

    -- Print the command list..
    cmds:ieach(function (v)
        print(chat.header(addon.name):append(chat.error('Usage: ')):append(chat.message(v[1]):append(' - ')):append(chat.color1(6, v[2])))
    end)
end

ashita.events.register('command', 'balloon_command_cb', function (e)
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
        print(chat.header(addon.name):append(chat.message('Display mode changed: ')):append(chat.success(tostring(balloon.settings.display_mode))))
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
            local old_theme_options = theme_options
            
            balloon.settings.theme = args[3]

            balloon.apply_theme()
            if theme_options ~= nil then
                print(chat.header(addon.name):append(chat.message('Theme changed: ')):append(chat.success(balloon.settings.theme)))
            else
                -- Restore old settings
                theme_options = old_theme_options
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
            print(chat.header(addon.name):append(chat.message('%s changed: '):format(setting_name)):append(chat.success('from ' .. setting_fmt .. ' to ' .. setting_fmt):format(old_val, balloon.settings[setting_key])))
            settings.save()
		else
			print(chat.header(addon.name):append(chat.message('%s: '):format(setting_name)):append(chat.success(setting_fmt):format(balloon.settings[setting_key])))
		end
        return
    end

    -- Handle toggle options
    -- Handle: /balloon animate
    -- Handle: /balloon portrait
    -- Handle: /balloon move_closes
    if (#args == 2 and args[2]:any('animate', 'portrait', 'move_closes')) then
        local setting_key_alias = {
            animate = 'animate_prompt',
            portrait = 'portraits',
            move_closes = 'move_close',
        }
        local setting_names = {
            animate_prompt = 'Animated text advance prompt',
            portraits = 'Display portraits',
            move_close = 'Close balloons on player movement',
        }
        local setting_key = setting_key_alias[args[2]] or args[2]
        local setting_name = setting_names[setting_key] or args[2]

        if #args > 2 then
            local old_val = balloon.settings[setting_key]
			balloon.settings[setting_key] = not balloon.settings[setting_key]

            -- Some additional logic we need to run depending on the setting change
            if setting_key == 'animate_prompt' then
                ui:position()
            elseif setting_key == 'portraits' then
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
    if (#args >= 3 and args[2]:any('test')) then
        local test_name = args[3]
        local lang = args[4] or balloon.lang_code
        local lang_map = {
            en = 1,
            ja = 2,
        }
        local lang_index = lang_map[lang] or 1

        local test_entry = tests[test_name]
        if test_entry == nil then
            print(chat.header(addon.name):append(chat.error('Invalid test: %s'):format(test_name)))
            return
        end

        local message = test_entry[lang_index]
        balloon.process_balloon('Test ' .. test_name .. ' : ' .. message, MODE.MESSAGE)
        return
    end

    -- Unhandled: Print help information..
    print_help(true)
end)

ashita.events.register('load', 'balloon_load', function()
    balloon.settings = settings.load(default_settings)

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

ashita.events.register('unload', 'balloon_unload', function ()
    print("balloon.unload")
    ui:destroy()
end)

ashita.events.register('packet_in', 'balloon_packet_in', function(e)
    if theme_options == nil then
        return
    end

	-- if S{'chunk', 'all'}[balloon.debug] then print("Chunk: " .. string.format('0x%02X', e.id) .. " original: " .. e.data_modified) end

	--会話中かの確認 (Check if you have left a conversation)
	if S{LEAVE_CONVERSATION_PACKET, ZONE_OUT_PACKET}[e.id] then
		balloon.close()
	end
end)

ashita.events.register('text_in', 'balloon_text_in', function (e)
    if theme_options == nil then
        return
    end

    if not balloon.processing_message then
        balloon.processing_message = true
        
        balloon.process_incoming_message(e)

        balloon.processing_message = false
    end
end)

ashita.events.register('d3d_present', 'balloon_d3d_present', function ()
    if theme_options == nil then
        return
    end

	-- animate our text advance indicator bouncing up and down
	balloon.frame_count = balloon.frame_count + 1
	if balloon.frame_count > 60*math.pi*2 then balloon.frame_count = balloon.frame_count - 60*math.pi*2 end

	if balloon.on then
		if balloon.settings.animate_prompt then
			ui:animate_prompt(balloon.frame_count)
		end
		ui:animate_text_display(balloon.settings.text_speed)
	end

    if not ui:hidden() then
        ui:render()
    end
end)

-- windower.register_event('keyboard',function(key_id,pressed,flags,blocked)
-- 	if windower.ffxi.get_info().chat_open or blocked then return end
-- 	if balloon.on == true then
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
