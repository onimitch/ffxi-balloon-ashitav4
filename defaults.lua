-- require('common')

local defaults = {}

defaults.DisplayMode = 2
defaults.MovementCloses = false
defaults.NoPromptCloseDelay = 10
defaults.AnimatePrompt = true
defaults.TextSpeed = 10
defaults.Theme = 'default'
defaults.Scale = 1
defaults.ShowPortraits = true

local scaling = require('scaling')
defaults.Position = {}
defaults.Position.X = scaling.window.w / 2
defaults.Position.Y = scaling.window.h - 258

return defaults