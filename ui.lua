local d3d = require('d3d8')
local ffi = require('ffi')
local C = ffi.C
local d3d8dev = d3d.get_device()

local gdi = require('gdifonts.include')

local PI2 = math.pi*2

local ui = {}

ui.message_background = nil
ui.portrait_background = nil
ui.portrait = nil
ui.portrait_frame = nil
ui.name_background = nil
ui.prompt = nil

ui.message_text = nil
ui.name_text = nil
ui.timer_text = nil

ui._hidden = true
ui._current_text = ''
ui._chars_shown = 0
ui._text_speed = 0
ui._has_portrait = false
ui._prompt_anim_time = 0

ui._dialogue_settings = {}
ui._system_settings = {}
ui._type = {}

ui._theme = 'default'
ui._scale = 1.0
ui._show_portraits = true
ui._theme_options = nil

ui._sprite = nil
ui._rect = ffi.new('RECT', { 0, 0, 100, 100, })
ui._vec_position = ffi.new('D3DXVECTOR2', { 0, 0, })
ui._vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, })


local function setup_image(image, path)
    image:path(path)
    image:repeat_xy(1, 1)
    image:draggable(false)
    image:fit(false) -- this does the opposite of what you'd expect, and also doesn't adjust :size() to account for it
end

local function setup_text(text, text_options)
    text:bg_alpha(0)
    text:bg_visible(false)
    text:font(unpack(text_options.font:split(',')))
    text:size(text_options.font_size)
    text:alpha(text_options.font_color.alpha)
    text:color(text_options.font_color.red, text_options.font_color.green, text_options.font_color.blue)
    text:stroke_transparency(text_options.stroke.alpha or 0)
    text:stroke_color(text_options.stroke.red or 0, text_options.stroke.green or 0, text_options.stroke.blue or 0)
    text:stroke_width(text_options.stroke.width or 0)
end

local function setup_sprite()
    if ui._sprite ~= nil then
        return
    end
    local sprite_ptr = ffi.new('ID3DXSprite*[1]');
    if (C.D3DXCreateSprite(d3d8dev, sprite_ptr) ~= C.S_OK) then
        error('failed to make sprite obj');
    end
    ui._sprite = d3d.gc_safe_release(ffi.cast('ID3DXSprite*', sprite_ptr[0]));
end

function ui:load(settings, theme_options)
    self._theme = settings.theme
    self._scale = settings.scale
    self._show_portraits = settings.portraits
    self._theme_options = theme_options
    self._text_speed = settings.text_speed

    self._dialogue_settings.path = theme_options.balloon_background
    self._dialogue_settings.color = {}
    self._dialogue_settings.color.alpha = theme_options.message.dialogue.alpha
    self._dialogue_settings.color.red = theme_options.message.dialogue.red
    self._dialogue_settings.color.green = theme_options.message.dialogue.green
    self._dialogue_settings.color.blue = theme_options.message.dialogue.blue
    self._dialogue_settings.items = theme_options.message.dialogue.items
    self._dialogue_settings.keyitems = theme_options.message.dialogue.keyitems
    self._dialogue_settings.gear = theme_options.message.dialogue.gear
    self._dialogue_settings.roe = theme_options.message.dialogue.roe
    self._dialogue_settings.emote = theme_options.message.dialogue.emote or '125,175,255'
    self._dialogue_settings.stroke = {}
    self._dialogue_settings.stroke.width = theme_options.message.dialogue.stroke.width
    self._dialogue_settings.stroke.alpha = theme_options.message.dialogue.stroke.alpha
    self._dialogue_settings.stroke.red = theme_options.message.dialogue.stroke.red
    self._dialogue_settings.stroke.green = theme_options.message.dialogue.stroke.green
    self._dialogue_settings.stroke.blue = theme_options.message.dialogue.stroke.blue

    self._system_settings.path = theme_options.system_background
    self._system_settings.color = {}
    self._system_settings.color.alpha = theme_options.message.system.alpha
    self._system_settings.color.red = theme_options.message.system.red
    self._system_settings.color.green = theme_options.message.system.green
    self._system_settings.color.blue = theme_options.message.system.blue
    self._system_settings.items = theme_options.message.system.items
    self._system_settings.keyitems = theme_options.message.system.keyitems
    self._system_settings.gear = theme_options.message.system.gear
    self._system_settings.roe = theme_options.message.system.roe
    self._system_settings.emote = theme_options.message.system.emote or '125,175,255'
    self._system_settings.stroke = {}
    self._system_settings.stroke.width = theme_options.message.system.stroke.width
    self._system_settings.stroke.alpha = theme_options.message.system.stroke.alpha
    self._system_settings.stroke.red = theme_options.message.system.stroke.red
    self._system_settings.stroke.green = theme_options.message.system.stroke.green
    self._system_settings.stroke.blue = theme_options.message.system.stroke.blue

    self._type = self._dialogue_settings

    setup_sprite()

    -- Create images
    self.message_background = images.new()
    self.portrait_background = images.new()
    self.portrait = images.new()
    self.portrait_frame = images.new()
    self.name_background = images.new()
    self.prompt = images.new()

    setup_image(self.message_background, self._type.path)
    if theme_options.portrait then
        setup_image(self.portrait_background, theme_options.portrait_background)
        setup_image(self.portrait, nil)
        setup_image(self.portrait_frame, theme_options.portrait_frame)
    end
    setup_image(self.name_background, theme_options.name_background)
    if theme_options.prompt then
        setup_image(self.prompt, theme_options.prompt_image)
    end

    -- Create text
    self.message_text = texts.new()
    self.name_text = texts.new()
    self.timer_text = texts.new()

    setup_text(self.message_text, theme_options.message)
    setup_text(self.name_text, theme_options.name)
    if theme_options.timer then
        setup_text(self.timer_text, theme_options.timer)
    end


    self:position(settings.position.x, settings.position.y)

    self.message_background:draggable(true)
end

function ui:destroy()
    ui._sprite = nil

    if ui.message_background ~= nil then 
        ui.message_background:destroy()
        ui.message_background = nil
    end
    if ui.portrait_background ~= nil then 
        ui.portrait_background:destroy()
        ui.portrait_background = nil
    end
    if ui.portrait ~= nil then 
        ui.portrait:destroy()
        ui.portrait = nil
    end
    if ui.portrait_frame ~= nil then 
        ui.portrait_frame:destroy()
        ui.portrait_frame = nil
    end
    if ui.name_background ~= nil then 
        ui.name_background:destroy()
        ui.name_background = nil
    end
    if ui.prompt ~= nil then 
        ui.prompt:destroy()
        ui.prompt = nil
    end

    if ui.message_text ~= nil then 
        ui.message_text:destroy()
        ui.message_text = nil
    end
    if ui.name_text ~= nil then 
        ui.name_text:destroy()
        ui.name_text = nil
    end
    if ui.timer_text ~= nil then 
        ui.timer_text:destroy()
        ui.timer_text = nil
    end

    gdi:destroy_interface()
end

function ui:scale(scale, position)
    self._scale = scale
    self:position(position.x, position.y)
end

function ui:text_speed(speed)
    self._text_speed = speed
end

function ui:window_size()
    return self._theme_options.message.width * self._scale, self._theme_options.message.height * self._scale
end

function ui:position(x, y, topleft_anchor)
    if x == nil then
        return self.message_background:pos_x(), self.message_background:pos_y()
    end

    topleft_anchor = topleft_anchor or false

    if not topleft_anchor then
        local center_offset_x = self._theme_options.message.width / 2
        x = x - center_offset_x * self._scale
        local center_offset_y = self._theme_options.message.height / 2
        y = y - center_offset_y * self._scale
    end

    local name_bg_offset_x = self._theme_options.name.background_offset_x * self._scale
    local name_bg_offset_y = self._theme_options.name.background_offset_y * self._scale

    local message_text_offset_x = self._theme_options.message.offset_x * self._scale
    local message_text_offset_y = self._theme_options.message.offset_y * self._scale
    if self._has_portrait and self._theme_options.portrait then
        if self._theme_options.portrait.message_offset_x then
            message_text_offset_x = self._theme_options.portrait.message_offset_x * self._scale
        end
        if self._theme_options.portrait.message_offset_y then
            message_text_offset_y = self._theme_options.portrait.message_offset_y * self._scale
        end
    end

    local name_text_offset_x = self._theme_options.name.offset_x * self._scale
    local name_text_offset_y = self._theme_options.name.offset_y * self._scale

    self.message_background:pos(x, y)
    self.message_background:size(self._theme_options.message.width * self._scale, self._theme_options.message.height * self._scale)

    if self._theme_options.portrait then
        local portrait_offset_x = self._theme_options.portrait.offset_x * self._scale
        local portrait_offset_y = self._theme_options.portrait.offset_y * self._scale
        self.portrait_background:pos(x + portrait_offset_x, y + portrait_offset_y)
        self.portrait_background:size(self._theme_options.portrait.width * self._scale, self._theme_options.portrait.height * self._scale)
        self.portrait:pos(x + portrait_offset_x, y + portrait_offset_y)
        self.portrait:size(self._theme_options.portrait.width * self._scale, self._theme_options.portrait.height * self._scale)
        self.portrait_frame:pos(x + portrait_offset_x, y + portrait_offset_y)
        self.portrait_frame:size(self._theme_options.portrait.width * self._scale, self._theme_options.portrait.height * self._scale)
    end

    self.name_background:pos(x + name_bg_offset_x, y + name_bg_offset_y)
    self.name_background:size(self._theme_options.name.width * self._scale, self._theme_options.name.height * self._scale)

    if self._theme_options.prompt then
        local prompt_offset_x = self._theme_options.prompt.offset_x * self._scale
        local prompt_offset_y = self._theme_options.prompt.offset_y * self._scale
        self.prompt:pos(x + prompt_offset_x, y + prompt_offset_y)
        self.prompt:size(self._theme_options.prompt.width * self._scale, self._theme_options.prompt.height * self._scale)
    end

    self.message_text:pos(x + message_text_offset_x, y + message_text_offset_y)
    self.message_text:size(self._theme_options.message.font_size * self._scale)

    local message_text_width = (self._theme_options.message.width - self._theme_options.message.margin_right) * self._scale - message_text_offset_x
    local message_text_height = self._theme_options.message.height * self._scale
    self.message_text:width(message_text_width)
    self.message_text:height(message_text_height)

    self.name_text:pos(x + name_text_offset_x, y + name_text_offset_y)
    self.name_text:size(self._theme_options.name.font_size * self._scale)

    if self._theme_options.timer then
        local timer_text_offset_x = self._theme_options.timer.offset_x * self._scale
        local timer_text_offset_y = self._theme_options.timer.offset_y * self._scale
        self.timer_text:pos(x + timer_text_offset_x, y + timer_text_offset_y)
        self.timer_text:size(self._theme_options.timer.font_size * self._scale)
    end
end

function ui:hide()
    self.message_background:hide()
    self.name_background:hide()
    self.portrait_background:hide()
    self.portrait:hide()
    self.portrait_frame:hide()
    self.prompt:hide()

    self.message_text:hide()
    self.name_text:hide()
    self.timer_text:hide()

    self._hidden = true
end

function ui:show(timed)
    self.message_background:show()
    self.message_text:show()

    if not S{'', ' '}[self.name_text:text()] then
        self.name_background:show()
        self.name_text:show()

        if self._has_portrait then
            self.portrait_background:show()
            self.portrait:show()
            self.portrait_frame:show()
        else
            self.portrait_background:hide()
            self.portrait:hide()
            self.portrait_frame:hide()
        end
    else
        self.name_background:hide()
        self.name_text:hide()

        self.portrait_background:hide()
        self.portrait:hide()
        self.portrait_frame:hide()
    end

    if not timed then
        self.prompt:show()
        self.timer_text:hide()
    else
        self.timer_text:show()
        self.prompt:hide()
    end

    self._hidden = false
end

function ui:set_type(type)
    local types = {
        --[190] = self._system_settings, -- system text (always a duplicate of 151?)
        [150] = self._dialogue_settings, -- npc text
        [151] = self._system_settings, -- system text
        [142] = self._dialogue_settings, -- battle text
        [144] = self._dialogue_settings, -- prompt-less npc text
        [146] = self._system_settings, -- "You hear something moving to the east..."
        [15] = self._system_settings, -- cutscene emote
    }
    self._type = types[type] or self._system_settings

    self:update_message_bg(self._type.path)
    self.message_text:alpha(self._type.color.alpha)
    self.message_text:color(self._type.color.red, self._type.color.green, self._type.color.blue)

    if type == 15 and self._type.emote ~= nil then
        local emote_col = self._type.emote:split(',')
        if #emote_col == 3 then
            self.message_text:color(tonumber(emote_col[1]), tonumber(emote_col[2]), tonumber(emote_col[3]))
        end
    end
    self.message_text:stroke_transparency(self._type.stroke.alpha)
    self.message_text:stroke_color(self._type.stroke.red, self._type.stroke.green, self._type.stroke.blue)
    self.message_text:stroke_width(self._type.stroke.width)
end

function ui:set_character(name)
    self.name_text:text(name)

    local zone_id = tonumber(AshitaCore:GetMemoryManager():GetParty():GetMemberZone(0))
    local zone_name = AshitaCore:GetResourceManager():GetString("zones.names", zone_id)
    local s = false
    if zone_name:endswith('[S]') then
        s = true
    end

    if self._show_portraits and self._theme_options.portrait then
        local theme_portrait = (addon.path..'/themes/'..self._theme..'/portraits/%s.png'):format(name)
        local theme_portrait_s = (addon.path..'/themes/'..self._theme..'/portraits/%s (S).png'):format(name)
        local portrait = (addon.path..'/portraits/%s.png'):format(name)
        local portrait_s = (addon.path..'/portraits/%s (S).png'):format(name)
        if s and ashita.fs.exists(theme_portrait_s) then
            self.portrait:path(theme_portrait_s)
            self._has_portrait = true
        elseif s and ashita.fs.exists(portrait_s) then
            self.portrait:path(portrait_s)
            self._has_portrait = true
        elseif ashita.fs.exists(theme_portrait) then
            self.portrait:path(theme_portrait)
            self._has_portrait = true
        elseif ashita.fs.exists(portrait) then
            self.portrait:path(portrait)
            self._has_portrait = true
        else
            self._has_portrait = false
        end
    else
        self._has_portrait = false
    end

    -- set a custom balloon based on npc name, if an image for them exists
    local fname = addon.path..'/themes/'..self._theme..('/characters/%s.png'):format(name)
	if ashita.fs.exists(fname) then
		self:update_message_bg(fname)
        return true
    end
    return false
end

function ui:update_message_bg(path)
    if path ~= self.message_background:path() then
        self.message_background:path(path)
    end
end

local function Tokenize(str)
	local result = {}
	for word in str:gmatch("%S+") do
		result[#result+1] = word
	end
	return result
end

function ui:wrap_text(str)
	local line_length = self._theme_options.message.max_length+1
    if self._has_portrait and self._theme_options.portrait.max_length then
        line_length = self._theme_options.portrait.max_length+1
    end
	local length_left = line_length
	local result = {}
	local line = {}

	for _, word in ipairs(Tokenize(str)) do
		if #word+1 > length_left then
			table.insert(result, table.concat(line, ' '))
			line = {word}
			length_left = line_length - #word
		else
			table.insert(line, word)
			length_left = length_left - (#word + 1)
		end
	end

	table.insert(result, table.concat(line, ' '):trimex())
	local new_str = table.concat(result, '\n '):trimex()

	return new_str
end

function ui:set_message(message)
    message = message or ''
    self._current_text = message
    self._char_length = utf8.len(message)
    self.message_text:text(message)

    if self._text_speed <= 0 or message == '' then
        self._chars_shown = self._char_length
        self.message_text:set_clip_range(nil)
    else
        self._chars_shown = 1
        self.message_text:set_clip_range(1,1)
    end

    -- this is here to update the layout depending if there's a portrait or not
    self:position(self.message_background:pos_x(), self.message_background:pos_y(), true)
end

local function smooth_sawtooth(time, frequency)
	local x = time * frequency
	return -math.sin(x - math.sin(x) / 2)
end

function ui:animate_prompt(delta_time)
    if not self._theme_options.prompt then return end

    local prompt_time = self._prompt_anim_time
    prompt_time = prompt_time + delta_time
    if prompt_time > PI2 then
        prompt_time = prompt_time - PI2
    end
    self._prompt_anim_time = prompt_time

    local amplitude = 2.5
	local bounceOffset = smooth_sawtooth(prompt_time, 6) * amplitude

	local pos_y = self.message_background:pos_y() + (self._theme_options.prompt.offset_y + bounceOffset) * self._scale
	self.prompt:pos_y(pos_y)
end

function ui:animate_text_display(char_count)
    if self._chars_shown >= self._char_length then
        return
    end

    self._chars_shown = math.min(self._char_length, self._chars_shown + char_count)
    if self._chars_shown == self._char_length then
        self.message_text:set_clip_range(nil)
    else
        self.message_text:set_clip_range(1, math.ceil(self._chars_shown))
    end
end

function ui:hidden()
    return self._hidden
end

local function render_image(sprite, image)
    if not image:visible() then
        return
    end

    local texture = image:texture()
    local vec_position = ui._vec_position
    local vec_scale = ui._vec_scale
    local rect = ui._rect

    rect.right = texture.width
    rect.bottom = texture.height
    vec_position.x = image:pos_x()
    vec_position.y = image:pos_y()

    -- Calc correct scale to render at
    vec_scale.x = image:width() / texture.width
    vec_scale.y = image:height() / texture.height

    local red, green, blue = image:color()
    local color = d3d.D3DCOLOR_ARGB(image:alpha(), red, green, blue)

    sprite:Draw(image:texture().ptr, rect, vec_scale, nil, 0.0, vec_position, color)
end

function ui:render(delta_time)
    if (self._sprite == nil) then return end

    self:animate_prompt(delta_time)
    self:animate_text_display(self._text_speed * delta_time)

    local sprite = self._sprite

    sprite:Begin()

    render_image(sprite, self.message_background)
    render_image(sprite, self.portrait_background)
    render_image(sprite, self.portrait)
    render_image(sprite, self.portrait_frame)
    render_image(sprite, self.name_background)
    render_image(sprite, self.prompt)

    self.message_text:render(sprite)
    self.name_text:render(sprite)
    self.timer_text:render(sprite)

    sprite:End()
end

return ui
