local config = require('wlibs.config')

local theme = {}

local def_file = 'theme.xml'
local addons_config_dir = ('%s/config/addons/%s/'):format(AshitaCore:GetInstallPath(), addon.name)

local apply_settings = function(theme_settings, lang_code)
    local options = {}

    options.balloon_background = theme_settings.theme_dir .. '/balloon.png'
    options.system_background = theme_settings.theme_dir .. '/system.png'
    options.portrait_background = theme_settings.theme_dir .. '/portrait-bg.png'
    options.portrait_frame = theme_settings.theme_dir .. '/portrait-frame.png'
    options.name_background = theme_settings.theme_dir .. '/name-bg.png'
    options.prompt_image = theme_settings.theme_dir .. '/advance-prompt.png'

    options.message = {}
    options.message.width = theme_settings.message.width
    options.message.height = theme_settings.message.height
    options.message.offset_x = theme_settings.message.textoffsetx
    options.message.offset_y = theme_settings.message.textoffsety
    options.message.margin_right = theme_settings.message.textmarginright or 0
    options.message.max_length = theme_settings.message.maxlength or 75
    local message_languages = {en=theme_settings.message.fontenglish, ja=theme_settings.message.fontjapanese}
    options.message.font = message_languages[lang_code]
    options.message.font_size = theme_settings.message.size
    options.message.font_color = {}
    options.message.font_color.alpha = theme_settings.message.dialogue.color.alpha
    options.message.font_color.red = theme_settings.message.dialogue.color.red
    options.message.font_color.green = theme_settings.message.dialogue.color.green
    options.message.font_color.blue = theme_settings.message.dialogue.color.blue
    options.message.bold = theme_settings.message.bold or theme_settings.message.dialogue.bold or false
    options.message.italic = theme_settings.message.italic or theme_settings.message.dialogue.italic or false

    options.message.dialogue = {}
    options.message.dialogue.alpha = theme_settings.message.dialogue.color.alpha
    options.message.dialogue.red = theme_settings.message.dialogue.color.red
    options.message.dialogue.green = theme_settings.message.dialogue.color.green
    options.message.dialogue.blue = theme_settings.message.dialogue.color.blue
    options.message.dialogue.items = theme_settings.message.dialogue.items
    options.message.dialogue.keyitems = theme_settings.message.dialogue.keyitems
    options.message.dialogue.gear = theme_settings.message.dialogue.gear
    options.message.dialogue.roe = theme_settings.message.dialogue.roe
    options.message.dialogue.emote = theme_settings.message.dialogue.emote
    options.message.stroke = {}
    options.message.dialogue.stroke = {}
    if theme_settings.message.dialogue.stroke then
        options.message.stroke.width = theme_settings.message.dialogue.stroke.width
        options.message.stroke.alpha = theme_settings.message.dialogue.stroke.alpha
        options.message.stroke.red = theme_settings.message.dialogue.stroke.red
        options.message.stroke.green = theme_settings.message.dialogue.stroke.green
        options.message.stroke.blue = theme_settings.message.dialogue.stroke.blue
        options.message.dialogue.stroke.width = theme_settings.message.dialogue.stroke.width
        options.message.dialogue.stroke.alpha = theme_settings.message.dialogue.stroke.alpha
        options.message.dialogue.stroke.red = theme_settings.message.dialogue.stroke.red
        options.message.dialogue.stroke.green = theme_settings.message.dialogue.stroke.green
        options.message.dialogue.stroke.blue = theme_settings.message.dialogue.stroke.blue
    end

    options.message.dialogue.bold = theme_settings.message.dialogue.bold or false
    options.message.dialogue.italic = theme_settings.message.dialogue.italic or false

    options.message.system = {}
    if theme_settings.message.system then
        options.message.system.alpha = theme_settings.message.system.color.alpha
        options.message.system.red = theme_settings.message.system.color.red
        options.message.system.green = theme_settings.message.system.color.green
        options.message.system.blue = theme_settings.message.system.color.blue
        options.message.system.items = theme_settings.message.system.items
        options.message.system.keyitems = theme_settings.message.system.keyitems
        options.message.system.gear = theme_settings.message.system.gear
        options.message.system.roe = theme_settings.message.system.roe
        options.message.system.emote = theme_settings.message.system.emote
        options.message.system.stroke = {}
        if theme_settings.message.system.stroke then
            options.message.system.stroke.width = theme_settings.message.system.stroke.width
            options.message.system.stroke.alpha = theme_settings.message.system.stroke.alpha
            options.message.system.stroke.red = theme_settings.message.system.stroke.red
            options.message.system.stroke.green = theme_settings.message.system.stroke.green
            options.message.system.stroke.blue = theme_settings.message.system.stroke.blue
        end

        options.message.system.bold = theme_settings.message.system.bold or false
        options.message.system.italic = theme_settings.message.system.italic or false
    else
        -- use dialogue settings if there are no system settings
        options.message.system = options.message.dialogue
    end

    options.name = {}
    options.name.width = theme_settings.npcname.width
    options.name.height = theme_settings.npcname.height
    options.name.offset_x = theme_settings.npcname.textoffsetx
    options.name.offset_y = theme_settings.npcname.textoffsety
    options.name.background_offset_x = theme_settings.npcname.offsetx
    options.name.background_offset_y = theme_settings.npcname.offsety
    options.name.font = theme_settings.npcname.font
    options.name.font_size = theme_settings.npcname.size
    options.name.font_color = {}
    options.name.font_color.alpha = theme_settings.npcname.color.alpha
    options.name.font_color.red = theme_settings.npcname.color.red
    options.name.font_color.green = theme_settings.npcname.color.green
    options.name.font_color.blue = theme_settings.npcname.color.blue
    options.name.stroke = {}
    if theme_settings.npcname.stroke then
        options.name.stroke.width = theme_settings.npcname.stroke.width
        options.name.stroke.alpha = theme_settings.npcname.stroke.alpha
        options.name.stroke.red = theme_settings.npcname.stroke.red
        options.name.stroke.green = theme_settings.npcname.stroke.green
        options.name.stroke.blue = theme_settings.npcname.stroke.blue
    end

    options.name.bold = theme_settings.npcname.bold or false
    options.name.italic = theme_settings.npcname.italic or false

    if theme_settings.portrait then
        options.portrait = {}
        options.portrait.width = theme_settings.portrait.width
        options.portrait.height = theme_settings.portrait.height
        options.portrait.offset_x = theme_settings.portrait.offsetx
        options.portrait.offset_y = theme_settings.portrait.offsety
        options.portrait.max_length = theme_settings.portrait.maxlength
        options.portrait.message_offset_x = theme_settings.portrait.messagetextoffsetx
        options.portrait.message_offset_y = theme_settings.portrait.messagetextoffsety
    end

    if theme_settings.prompt then
        options.prompt = {}
        options.prompt.width = theme_settings.prompt.width
        options.prompt.height = theme_settings.prompt.height
        options.prompt.offset_x = theme_settings.prompt.offsetx
        options.prompt.offset_y = theme_settings.prompt.offsety
    end

    options.timer = {}
    if theme_settings.timer then
        options.timer.offset_x = theme_settings.timer.textoffsetx or theme_settings.prompt.offsetx
        options.timer.offset_y = theme_settings.timer.textoffsety or theme_settings.prompt.offsety
        options.timer.font = theme_settings.timer.font or theme_settings.npcname.font

        options.timer.font_size = theme_settings.message.size
        if type(theme_settings.timer.size) == 'number' then
            options.timer.font_size = theme_settings.timer.size
        end

        options.timer.font_color = {}
        if theme_settings.timer.color then
            options.timer.font_color.alpha = theme_settings.timer.color.alpha
            options.timer.font_color.red = theme_settings.timer.color.red
            options.timer.font_color.green = theme_settings.timer.color.green
            options.timer.font_color.blue = theme_settings.timer.color.blue
        else
            options.timer.font_color = options.message.font_color
        end
        options.timer.stroke = {}
        if theme_settings.timer.stroke then
            options.timer.stroke.width = theme_settings.timer.stroke.width
            options.timer.stroke.alpha = theme_settings.timer.stroke.alpha
            options.timer.stroke.red = theme_settings.timer.stroke.red
            options.timer.stroke.green = theme_settings.timer.stroke.green
            options.timer.stroke.blue = theme_settings.timer.stroke.blue
        else
            options.timer.stroke = options.message.stroke
        end

        options.timer.bold = theme_settings.timer.bold or false
        options.timer.italic = theme_settings.timer.italic or false
    else
        -- use prompt position and message font settings, if no timer settings exist in the theme
        options.timer.offset_x = theme_settings.prompt.offsetx
        options.timer.offset_y = theme_settings.prompt.offsety
        options.timer.font = options.message.font
        options.timer.font_size = options.message.font_size
        options.timer.font_color = options.message.font_color
        options.timer.stroke = options.message.stroke
        options.timer.bold = options.message.bold
        options.timer.italic = options.message.italic
    end

    return options
end

theme.load = function(theme_name, lang_code)
    local theme_dir = addon.path .. 'themes/' .. theme_name
    local theme_dir_user = addons_config_dir .. 'themes/' .. theme_name

    -- Check if there is a user theme first
    if ashita.fs.exists(theme_dir_user .. '/' .. def_file) then
        theme_dir = theme_dir_user
    -- Fall back to built in themes dir
    elseif not ashita.fs.exists(theme_dir .. '/' .. def_file) then
        print('Theme not found: ' .. theme_name .. ', searched: "' .. theme_dir .. '" and "' .. theme_dir_user .. '"')
        return nil
    end

    -- Load XML theme file
    local theme_def_path = theme_dir .. '/' .. def_file
	local theme_settings = config.load(theme_def_path, {['name']=theme_name, ['theme_dir']=theme_dir})
    return apply_settings(theme_settings, lang_code)
end

return theme