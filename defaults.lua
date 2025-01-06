require('common')

local defaults = T{}

defaults.display_mode = 2
defaults.move_close = true
defaults.no_prompt_close_delay = 10
defaults.text_speed = 100
defaults.theme = 'default'
defaults.scale = 1
defaults.portraits = true
defaults.always_on_top = true
defaults.in_combat = false
defaults.cinematic = true
defaults.system_messages = true

defaults.additional_chat_modes = {
    144
}

local scaling = require('scaling')
defaults.position = {}
defaults.position.x = scaling.window.w / 2
defaults.position.y = scaling.window.h - 258

return defaults