local ffi = require('ffi');
ffi.cdef[[
    int MultiByteToWideChar(uint32_t CodePage, uint32_t dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar_t* lpMultiByteStr, int32_t cchWideChar);
    int WideCharToMultiByte(uint32_t CodePage, uint32_t dwFlags, wchar_t* lpWideCharString, int32_t cchWideChar, char* lpMultiByteStr, int32_t cbMultiByte, char lpDefaultChar);
]]

local exports = T{};

local code_page = {
    utf8 = 65001,
    shiftjis = 932,
};

local function Convert_String(input, codepage_from, codepage_to)
    input = tostring(input or '');
    local source_length = string.len(input);
    local cbuffer = ffi.new('char[?]', source_length+1);
    ffi.copy(cbuffer, input);

    local wchar_Length = ffi.C.MultiByteToWideChar(codepage_from, 0, cbuffer, -1, nil, 0);
    local wbuffer = ffi.new('wchar_t[?]', wchar_Length);
    ffi.C.MultiByteToWideChar(codepage_from, 0, cbuffer, -1, wbuffer, wchar_Length);

    local char_length = ffi.C.WideCharToMultiByte(codepage_to, 0, wbuffer, -1, nil, 0, 0)
    cbuffer = ffi.new('char[?]', char_length);
    ffi.C.WideCharToMultiByte(codepage_to, 0, wbuffer, -1, cbuffer, char_length, 0);

    return ffi.string(cbuffer);
end

function exports:ShiftJIS_To_UTF8(input)
    return Convert_String(input, code_page.shiftjis, code_page.utf8);
end

function exports:UTF8_To_ShiftJIS(input)
    return Convert_String(input, code_page.utf8, code_page.shiftjis);
end

return exports;