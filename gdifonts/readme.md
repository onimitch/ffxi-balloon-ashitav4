# GdiFonts
GdiFonts is a library you can use to display high quality fonts in your Ashita4 addons.  It is optimized
in a way that fonts will have minimal cost to display except when changing, but please note that Gdiplus is
not hardware accelerated and it will still not be as performant as ashita font objects for rapidly updating text.
If you have text that will be changing every frame, consider limiting number of objects and profiling performance.
The compiled dll included in this library is open source and can be located at:<br>
https://github.com/ThornyFFXI/gdifonttexture
<br><br>

## Initializing the library
Create a folder named 'gdifonts' in your addon.  Copy the files from this repo into that folder.  Include the library
with:
```
local gdi = require('gdifonts.include');
```
Note that you may use any variable name or dependency directory you want, as long as all files remain in the same directory.
You must also add this call to unload to ensure proper cleanup:
```
gdi:destroy_interface();
```
<br><br>

## Creating a managed font object
GdiFonts creates class objects to manage each font.  Each object must be populated with the following settings table:
```
local fontSettings = {
    box_height = 0,
    box_width = 0,
    font_alignment = gdi.Alignment.Left,
    font_color = 0xFFFFFFFF,
    font_family = 'Grammara',
    font_flags = gdi.FontFlags.None,
    font_height = 18,
    gradient_color = 0x00000000,
    gradient_style = gdi.Gradient.None,
    outline_color = 0xFF000000,
    outline_width = 2,
    position_x = 0,
    position_y = 0,
    visible = true,
    text = '',
};
```
Once you've created the settings table, you can create a managed font object with this call:
```
local myFontObject = gdi:create_object(fontSettings, false);
```
To destroy the object, use this call:
```
gdi:destroy_object(myFontObject);
```
You do not need to destroy managed font objects on unload; destroying the interface will handle it.
If you only want to temporarily hide the object, you should use the set_visible method instead of destroying it.<br><br>


## Modifying a font object
To update the object's text or parameters, you can use any of these calls, which set the same values in defaults:
```
myFontObject:set_box_height(height); --Sets maximum height of font.  Accepts a number, 0 will be treated as no maximum.
myFontObject:set_box_width(width); --Sets maximum width of displayed font.  Accepts a number, 0 will be treated as no maximum.
myFontObject:set_font_alignment(alignment);  --Sets font alignment.  Accepts gdi.Aligment.Left, gdi.Alignment.Center, or gdi.Alignment.Right.
myFontObject:set_font_color(color);  --Sets font color.  Accepts a 32 bit ARGB value.
myFontObject:set_font_family(family); --Sets font family.  Accepts a string.
myFontObject:set_font_flags(flags); --Sets font flags.  Accepts gdi.FontFlags.None, gdi.FontFlags.Bold, gdi.FontFlags.Italic, gdi.FontFlags.Underline, gdi.FontFlags.Strikeout, or a combination using bitwise or.
myFontObject:set_font_height(height); --Sets font height.  Accepts a number.
myFontObject:set_gradient_color(color); --Sets a color for the font gradient to blend into.  Accepts a 32 bit ARGB value.
myFontObject:set_gradient_style(style); --Sets a gradient style.  Styles are located in gdi.Gradient table.
myFontObject:set_outline_color(color); --Sets a color for the font outline.  Accepts a 32 bit ARGB value.
myFontObject:set_outline_width(width); --Sets width of outline.  Accepts a number, use 0 to disable outlines.
myFontObject:set_position_x(position); --Relocates the object.  Accepts a number.  Does nothing for unmanaged objects.
myFontObject:set_position_y(position); --Relocates the object.  Accepts a number.  Does nothing for unmanaged objects.
myFontObject:set_text(text); --Updates font object text.  Accepts a string.
myFontObject:set_visible(visible);  --Draws or hides the object.  Accepts a boolean.  Does nothing for unmanaged objects.
```

## Altering render time
By default, objects are created as managed.  This means GdiFonts will track and render them, and all you need to do is change the parameters.
If you need to render at a specific time, you can use this function to toggle automatic rendering of managed objects:
```
gdi:set_auto_render(enabled);
```
When auto render is disabled, you must call:
```
gdi:render();
```
during every frame you want your managed objects to appear, at the time you want them to be drawn.<br><br>

## Unmanaged Font Objects
If you need further control than that, you can still use this library to create unmanaged objects by specifying true for the second parameter of
create_object as so:
```
local myFontObject = gdi:create_object(default_settings, true);
```
This will make you fully responsible for the object, and you must call:
```
gdi:destroy_object(myFontObject);
```
upon unload for every unmanaged object to avoid memory leaks.  To render an unmanaged object, you can use this call:
```
local texture, rect = fontObject:get_texture();
```
This will return nil if the object has no text, or cannot be rendered.  Otherwise, it will give you a texture and the rect within the texture where the font is located.  You can use these to draw via sprite as you see fit.

## Font Helper Function
This is a small extra, but it is tedious to do from lua, so I have included it here.  It may be moved elsewhere eventually.
If you need to check if a font is available on the system, you can use this call:
```
local font = 'Grammara';
local isAvailable = gdi:get_font_available(font);
```
It will return true or false, depending on if the system has the font.

## Using Japanese FFXI resources
Because FFXI resources are stored in Shift-JIS, they must be converted to render properly.  You can accomplish this using the included encoding lib.  Simply require the lib, and use the function ShiftJIS_To_UTF8 prior to rendering your text.
```
local encoding = require('gdifonts.encoding');
local sjResource = AshitaCore:GetResourceManager():GetString('zones.names', 60, 1);
local utf8Resource = encoding:ShiftJIS_To_UTF8(sjResource);
```

You can also convert back to shift-JIS if necessary.
```
local sjResourceAgain = encoding:UTF8_to_ShiftJIS(utf8Resource);
```