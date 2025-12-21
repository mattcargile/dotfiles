local wezterm = require 'wezterm'
local config = wezterm.config_builder() 
config.color_scheme = 'Dracula (Official)'
--config.font = wezterm.font 'CaskaydiaCove Nerd Font'
config.font = wezterm.font 'MonoLisa Nerd Font'
config.default_prog = { 'pwsh', '-Login', '-NoExit' }
config.keys = {
  { key = 'l', mods = 'ALT', action = wezterm.action.ShowLauncher },
}
return config

