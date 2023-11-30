--[[
Copyright 2023 Thorny

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--

local d3d = require('d3d8');
local ffi = require('ffi');

local default_settings = {
    box_height = 0,
    box_width = 0,
    font_alignment = 0,
    font_color = 0xFFFFFFFF,
    font_family = 'Arial',
    font_flags = 0,
    font_height = 18,
    gradient_color = 0x00000000,
    gradient_style = 0,
    outline_color = 0xFF000000,
    outline_width = 2,

    position_x = 0,
    position_y = 0,
    visible = true,
    text = '',
};

local function CreateFontData(settings)
    local container = {};
    local region_count = 0;
    local regions = nil;
    local ranges = {};

    if(settings.regions ~= nil and type(settings.regions) == 'table') then
        region_count = table.length(settings.regions);

        regions = ffi.new('GdiRegion_t[?]', region_count);
        local i = 0;
        for k, r in pairs(settings.regions) do
            -- Parse font color from key
            local colors = k:split(',');
            regions[i].FontColor = d3d.D3DCOLOR_ARGB(255, colors[1], colors[2], colors[3]);
            -- For now we just use same outline color
            regions[i].OutlineColor = settings.outline_color;

            local ranges_arr = ffi.new('GdiCharRange_t[?]', #r);
            for j, range in ipairs(r) do
                ranges_arr[j-1] = { range.start_u-1, range.length_u };
            end
            regions[i].Ranges = ranges_arr;
            regions[i].RangesLength = #r;
            
            i = i + 1;

            -- Make sure we keep the cdata referenced in lua so data is collected by GC
            table.insert(ranges, ranges_arr);
        end
    end

    -- Make sure we keep the cdata referenced in lua so data is collected by GC
    container.cdata_regions = regions;
    container.cdata_ranges = ranges;

    container.data = ffi.new('GdiFontData_t', {
        BoxHeight = settings.box_height,
        BoxWidth = settings.box_width,
        FontHeight = settings.font_height,
        OutlineWidth = settings.outline_width,
        FontFlags = settings.font_flags,
        FontColor = settings.font_color,
        OutlineColor = settings.outline_color,
        GradientStyle = settings.gradient_style,
        GradientColor = settings.gradient_color,
        FontFamily = settings.font_family,
        FontText = settings.text,
        Regions = container.cdata_regions,
        RegionsLength = region_count,
    });

    return container;
end

local object = {};

function object:destroy()
    self.rect = nil;
    self.texture = nil;
end

function object:get_texture()
    if (self.is_dirty == true) then
        self.is_dirty = false;
        self.texture = nil;
        self.rect = nil;
        if (self.settings.text == '') then
            return;
        end
        local fd = CreateFontData(self.settings);
        local tx = self.renderer.CreateTexture(self.interface, fd.data);
        if (tx.Texture == nil) or (tx.Width == 0) or (tx.Height == 0) then
            return;
        else
            self.texture = d3d.gc_safe_release(tx.Texture);
            self.rect = ffi.new('RECT', { 0, 0, tx.Width, tx.Height });
        end
    end

    return self.texture, self.rect;
end

function object:new(renderer, interface, settings)
    local o = {};
    setmetatable(o, self);
    self.__index = self;
    o.is_dirty = true;
    o.interface = interface;
    o.renderer = renderer;
    o.settings = {};
    for key,value in pairs(default_settings) do
        if (type(settings) == 'table') and (settings[key] ~= nil) then
            o.settings[key] = settings[key];
        else
            o.settings[key] = value;
        end
    end
    return o;
end

function object:set_box_height(height)
    if (self.settings.box_height ~= height) then
        self.is_dirty = true;
    end
    self.settings.box_height = height;
end
    
function object:set_box_width(width)
    if (self.settings.box_width ~= width) then
        self.is_dirty = true;
    end
    
    self.settings.box_width = width;
end

function object:set_regions(regions)
    self.is_dirty = true;
    self.settings.regions = regions;
end

function object:set_font_alignment(alignment)
    self.settings.font_alignment = alignment;
end

function object:set_font_color(color)
    if (color ~= self.settings.font_color) then
        self.is_dirty = true;
    end

    self.settings.font_color = color;
end

function object:set_font_family(family)
    if (family ~= self.settings.font_family) then
        self.is_dirty = true;
    end

    self.settings.font_family = family;
end

function object:set_font_flags(flags)
    if (flags ~= self.settings.font_flags) then
        self.is_dirty = true;
    end

    self.settings.font_flags = flags;
end

function object:set_font_height(height)
    if (height ~= self.settings.font_height) then
        self.is_dirty = true;
    end

    self.settings.font_height = height;
end

function object:set_gradient_color(color)
    if (color ~= self.settings.gradient_color) then
        self.is_dirty = true;
    end

    self.settings.gradient_color = color;
end

function object:set_gradient_style(style)
    if (style ~= self.settings.gradient_style) then
        self.is_dirty = true;
    end

    self.settings.gradient_style = style;
end

function object:set_outline_color(color)
    if (color ~= self.settings.outline_color) then
        self.is_dirty = true;
    end

    self.settings.outline_color = color;
end

function object:set_outline_width(width)
    if (width ~= self.settings.outline_width) then
        self.is_dirty = true;
    end

    self.settings.outline_width = width;
end

function object:set_position_x(x)
    self.settings.position_x = x;
end

function object:set_position_y(y)
    self.settings.position_y = y;
end

function object:set_text(text)
    if (text ~= self.settings.text) then
        self.is_dirty = true;
    end

    self.settings.text = text;
end

function object:set_visible(visible)
    self.settings.visible = visible;
end

return object;