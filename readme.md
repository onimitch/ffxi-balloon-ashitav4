# Balloon (Ashita v4 Port)

This is an [Ashita v4](https://github.com/AshitaXI/Ashita-v4beta) port of the Balloon addon, forked from [StarlitGhost's version](https://github.com/StarlitGhost/Balloon).

The original Windower Balloon addon was created by Hando and modified by Kenshi, Yuki and Ghosty.

This Ashita v4 port was created by onimitch.

![Example default](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-default.png "Example default")

## How to install:
1. Download the latest Release from the [Releases page](https://github.com/onimitch/ffxi-balloon-ashitav4/releases)
2. Extract the **_balloon_** folder to your **_Ashita4/addons_** folder

## How to enable it in-game:
1. Login to your character in FFXI
2. Type `/addon load balloon`

## How to have Ashita load it automatically:
1. Go to your Ashita v4 folder
2. Open the file **_Ashita4/scripts/default.txt_**
3. Add `/addon load balloon` to the list of addons to load under "Load Plugins and Addons"

## Commands

You can use `/balloon` or `/bl`

`/balloon 0` - Hide balloon & display npc text in game log window.

`/balloon 1` - Show balloon & hide npc text from game log window.

`/balloon 2` - Show balloon & display npc text in game log window.

`/balloon reset` - Reset all settings back to default.

`/balloon reset pos` - Reset the balloon position.

`/balloon theme <theme>` - Switch theme (see below for info on Themes).

`/balloon scale <scale>` - Scales the size of the balloon by a decimal (eg: 1.5).

`/balloon delay <seconds>` - Delay before closing promptless balloons.

`/balloon speed <chars per second>` - Speed that text is displayed, in characters per second. Set to 0 to disable.

`/balloon portrait` - Toggle the display of character portraits, if the theme has settings for them.

`/balloon move_closes` - Toggle balloon auto-close on player movement.

`/balloon test <name> <lang> <mode>` - Display a test bubble. Lang: "-" (auto), "en" or "ja". Mode: 1 (dialogue), 2 (system).

`/balloon test` - List all available tests.

## Moving balloon

While the balloon is open you can use the mouse to click and drag it to move it around.

## Themes

There are currently four themes bundled with the addon.

### default

![Example default](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-default.png "Example default")

### ffvii-r

Requires "Libre Franklin Medium" or "Libre Franklin Regular" font, which you can get free from [Google Fonts](https://fonts.google.com/specimen/Libre+Franklin). Install the font in Windows.

![Example ffvii-r](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-ffvii-r.png "Example ffvii-r")

### ffxi

![Example ffxi](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-ffxi.png "Example ffxi")

### snes-ff

Uses "DotGothic16" font, which you can get free from [Google Fonts](https://fonts.google.com/specimen/DotGothic16). Install the font in Windows.

Alternatively it will look for "DePixel" font if "DotGothic16" not installed, which you can get free from [Be Fonts](https://befonts.com/depixel-font-family.html).

![Example snes-ff](https://github.com/onimitch/ffxi-balloon-ashitav4/blob/main/Example-snes-ff.png "Example snes-ff")

## Theme customisation

If you want to customise a theme, copy one of the existing themes from `addons/balloon/themes` into `config/addons/balloon/themes`.

Example: `config/addons/balloon/themes/my_theme`.

In game switch to your new theme: `/balloon theme my_theme`.

Edit the theme.xml file as you wish, or replace the pngs with alternatives. Sorry there isn't any more help on this for now but hopefully the existing themes are enough to figure out how it works.

Reload the theme by using: `/balloon theme my_theme`.

See your changes immediately by using one of the test prompts:

e.g: `/balloon test bahamut` or `/balloon test colors`.


## Issues/Support

I only have limited time available to offer support, but if you have a problem, have discovered a bug or want to request a feature, please [create an issue on GitHub](https://github.com/onimitch/ffxi-balloon-ashitav4/issues).

## Gdifonts

This addon uses a custom fork of ThornyXI's gdifonts and gdifonttextures, in order to support colored regions and clipping:

https://github.com/onimitch/gdifonts/tree/regions

https://github.com/onimitch/gdifonttexture/tree/regions
