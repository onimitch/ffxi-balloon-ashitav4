--[[
Copyright 2023 Thorny

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

]]--

local function GetLibPath()
  return debug.getinfo(2, "S").source:sub(2);
end

local libPath    = GetLibPath();
local d3d        = require('d3d8');
local ffi        = require('ffi');
local fontobject = dofile(string.gsub(libPath, 'include.lua', 'fontobject.lua'));
local renderer   = ffi.load(string.gsub(libPath, 'include.lua', 'gdifonttexture.dll'));
ffi.cdef[[
    typedef struct {
        int32_t  BoxHeight;
        int32_t  BoxWidth;
        float    FontHeight;
        float    OutlineWidth;
        uint32_t FontFlags;
        uint32_t FontColor;
        uint32_t OutlineColor;
        uint32_t GradientStyle;
        uint32_t GradientColor;
        char     FontFamily[256];
        char     FontText[4096];
    } GdiFontData_t;

    typedef struct {
        int32_t            Width;
        int32_t            Height;
        IDirect3DTexture8* Texture;
    } GdiFontReturn_t;

    uint32_t* CreateFontManager(IDirect3DDevice8* pDevice);
    void DestroyFontManager(uint32_t* pManager);
    GdiFontReturn_t CreateTexture(uint32_t* pManager, GdiFontData_t* data);
    bool GetFontAvailable(const char* font);
]]

local interface = renderer.CreateFontManager(d3d.get_device());
local objects = T{};

-- Render stuff..
local sprite = ffi.new('ID3DXSprite*[1]');
if (ffi.C.D3DXCreateSprite(d3d.get_device(), sprite) == ffi.C.S_OK) then
    sprite = d3d.gc_safe_release(ffi.cast('ID3DXSprite*', sprite[0]));
else
    sprite = nil;
end
local vec_position = ffi.new('D3DXVECTOR2', { 0, 0, });
local vec_scale = ffi.new('D3DXVECTOR2', { 1.0, 1.0, });
local d3dwhite = d3d.D3DCOLOR_ARGB(255, 255, 255, 255);
local autoRender = false;

local function render_objects()
    if (sprite ~= nil) then
        sprite:Begin();
        for _,obj in ipairs(objects) do
            if (obj.settings.visible) then
                local texture, rect = obj:get_texture();
                if (texture ~= nil) then
                    if (obj.settings.font_alignment == 1) then
                        vec_position.x = obj.settings.position_x - (rect.right / 2);
                    elseif (obj.settings.font_alignment == 2) then
                        vec_position.x = obj.settings.position_x - rect.right;
                    else
                        vec_position.x = obj.settings.position_x;
                    end
                    vec_position.y = obj.settings.position_y;
                    sprite:Draw(texture, rect, vec_scale, nil, 0.0, vec_position, d3dwhite);
                end
            end
        end
        sprite:End();
    end
end

-- Library exports..
local exports = {};

exports.FontFlags = {
    None = 0,
    Bold = 1,
    Italic = 2,
    Underline = 4,
    Strikeout = 8
};

exports.Alignment = {
    Left = 0,
    Center = 1,
    Right = 2
};

exports.Gradient = {
    None = 0,
    LeftToRight = 1,
    TopLeftToBottomRight = 2,
    TopToBottom = 3,
    TopRightToBottomLeft = 4,
    RightToLeft = 5,
    BottomRightToTopLeft = 6,
    BottomToTop = 7,
    BottomLeftToTopRight = 8
};

function exports:create_object(settings, manual)
    if (interface == nil) then
        error('Interface doesn\'t exist.');
        return;
    end

    local obj = fontobject:new(renderer, interface, settings);
    if (manual ~= true) then
        objects:append(obj);
    end
    return obj;
end

function exports:destroy_interface()
    for _,object in ipairs(objects) do
        object:destroy();
    end
    objects = T{};
    renderer.DestroyFontManager(interface);
end

function exports:destroy_object(fontObject)
    local newTable = T{};
    for _,object in ipairs(objects) do
        if (object ~= fontObject) then
            newTable:append(object);
        end
    end
    objects = newTable;
    fontObject:destroy();
end

function exports:get_font_available(fontName)
    return renderer.GetFontAvailable(fontName);
end

function exports:render()
    render_objects();
end

function exports:set_auto_render(enabled)
    local newSetting = (enabled == true);
    if (autoRender ~= newSetting) then
        autoRender = newSetting;
        if autoRender then
            ashita.events.register('d3d_present', 'gdifonts_render_tick', render_objects);
        else
            ashita.events.unregister('d3d_present', 'gdifonts_render_tick');
        end
    end
end
exports:set_auto_render(true);

return exports;