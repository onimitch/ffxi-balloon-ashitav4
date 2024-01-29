require('common')

local defaults = T{}

defaults.display_mode = 2
defaults.move_close = true
defaults.no_prompt_close_delay = 10
defaults.text_speed = 100
defaults.theme = 'default'
defaults.scale = 1
defaults.portraits = true
defaults.filter = {
    timed_battle = true,
    timed_message = true,
}

local scaling = require('scaling')
defaults.position = {}
defaults.position.x = scaling.window.w / 2
defaults.position.y = scaling.window.h - 258

return defaults