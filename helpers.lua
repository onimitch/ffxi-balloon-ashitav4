require('win32types')
local ffi = require('ffi')

local helpers = {}

-- game menu

local pGameMenu = ashita.memory.find('FFXiMain.dll', 0, '8B480C85C974??8B510885D274??3B05', 16, 0)
helpers.get_game_menu_name = function()
    local menu_pointer = ashita.memory.read_uint32(pGameMenu)
    local menu_val = ashita.memory.read_uint32(menu_pointer)
    if menu_val == 0 then
        return ''
    end
    local menu_header = ashita.memory.read_uint32(menu_val + 4)
    local menu_name = ashita.memory.read_string(menu_header + 0x46, 16)
    return string.gsub(menu_name, '\x00', ''):trimex()
end
helpers.is_chat_open = function()
    local menu_name = helpers.get_game_menu_name()
    return menu_name:match('menu[%s]+inline') ~= nil
end
helpers.is_dialog_option_open = function()
    local menu_name = helpers.get_game_menu_nam()
    return menu_name:match('menu[%s]+query') ~= nil
end

-- event system

local pEventSystem = ashita.memory.find('FFXiMain.dll', 0, 'A0????????84C0741AA1????????85C0741166A1????????663B05????????0F94C0C3', 0, 0)
helpers.is_event_system_active = function()
    if pEventSystem == 0 then
        return false
    end
    local ptr = ashita.memory.read_uint32(pEventSystem + 1)
    if ptr == 0 then
        return false
    end

    return ashita.memory.read_uint8(ptr) == 1
end

-- interface hidden

local pInterfaceHidden = ashita.memory.find('FFXiMain.dll', 0, '8B4424046A016A0050B9????????E8????????F6D81BC040C3', 0, 0)
helpers.is_game_interface_hidden = function()
    if pInterfaceHidden == 0 then
        return false
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10)
    if ptr == 0 then
        return false
    end

    return ashita.memory.read_uint8(ptr + 0xB4) == 1
end

helpers.set_game_interface_hidden = function(hidden)
    if pInterfaceHidden == 0 then
        return false
    end
    local ptr = ashita.memory.read_uint32(pInterfaceHidden + 10)
    if ptr == 0 then
        return false
    end

    local new_value = hidden and 1 or 0
    -- print('set_game_interface_hidden: ' .. tostring(hidden))
    ashita.memory.write_uint8(ptr + 0xB4, new_value)
    return true
end

-- user camera

local userCamera = {
    -- The pattern here is part of the function XiActor::DisableUserControlCamera which the offset
    -- is to the global enable_user_control_camera value (@atom0s)
    DisableUserControlCamera_func_ptr = ashita.memory.find('FFXiMain.dll', 0, '80A0B2000000FBC605????????00', 0, 0),
}

helpers.is_user_camera_enabled = function()
    if userCamera.DisableUserControlCamera_func_ptr == 0 then
        return nil
    end

    if userCamera.enable_user_control_camera_ptr == nil then
        local enable_user_control_camera_addr = ashita.memory.read_uint32(userCamera.DisableUserControlCamera_func_ptr + 0x09)
        if enable_user_control_camera_addr == 0 then
            error('Failed to get enable_user_control_camera_addr')
            return nil
        end
        userCamera.enable_user_control_camera_ptr = ffi.cast('bool*', enable_user_control_camera_addr)
    end

    -- local enable_user_control_camera = ffi.cast('bool*', userCamera.enable_user_control_camera_ptr)
    if userCamera.enable_user_control_camera_ptr ~= nil then
        return userCamera.enable_user_control_camera_ptr[0]
    end

    return nil
    -- print('enable_user_control_camera: ' .. tostring(userCamera.enable_user_control_camera_ptr[0]))
end

-- stepdialog (by @atom0s)

ffi.cdef [[
    typedef void (__thiscall* TkEventMsg2_OnKeyDown_f)(int32_t, int16_t, int16_t)
]]

local stepdialog = T{
    ptrs = T{
        func = ashita.memory.find('FFXiMain.dll', 0, '538B5C240856578B7C24148BF15753E8????????8B0D????????3BF174', 0, 0),
        this = ashita.memory.find('FFXiMain.dll', 0, '8B0D????????85C90F??????????8B410885C00F', 2, 0),
    },
}
helpers.stepdialog = {}
helpers.stepdialog.available = stepdialog.ptrs:all(function(v) return v ~= nil and v ~= 0; end)
helpers.stepdialog.run = function()
    if stepdialog.ptrs.func == nil or stepdialog.ptrs.func == 0 or
        stepdialog.ptrs.this == nil or stepdialog.ptrs.this == 0 then
        return false
    end

    -- Obtain the current TkEventMsg2 object pointer
    local ptr = ashita.memory.read_uint32(stepdialog.ptrs.this)
    if ptr == nil or ptr == 0 then
        return false
    end
    ptr = ashita.memory.read_uint32(ptr)
    if ptr == nil or ptr == 0 then
        return false
    end

    -- Obtain the TkEventMsg2::OnKeyDown function pointer
    local func = ffi.cast('TkEventMsg2_OnKeyDown_f', stepdialog.ptrs.func)
    if func == nil or func == 0 then
        return false
    end

    -- Invoke the function with an enter press
    func(ptr, 5, 0xFFFF)
    return true
end

return helpers
