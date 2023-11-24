require('common')

local defaults = T{}

defaults.display_mode = 2
defaults.move_close = false
defaults.no_prompt_close_delay = 10
defaults.animate_prompt = true
defaults.text_speed = 10
defaults.theme = 'default'
defaults.scale = 1
defaults.portraits = true

local scaling = require('scaling')
defaults.position = {}
defaults.position.x = scaling.window.w / 2
defaults.position.y = scaling.window.h - 258

return defaults