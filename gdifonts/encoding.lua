local ffi = require('ffi');
ffi.cdef[[
    int MultiByteToWideChar(uint32_t CodePage, uint32_t dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar_t* lpMultiByteStr, int32_t cchWideChar);
    int WideCharToMultiByte(uint32_t CodePage, uint32_t dwFlags, wchar_t* lpWideCharString, int32_t cchWideChar, char* lpMultiByteStr, int32_t cbMultiByte, char lpDefaultChar);
]]

local exports = T{};

encoding_report = {}
encoding_report.source_length = 0
encoding_report.wchar_Length = 0
encoding_report.char_length = 0

local function Convert_String(input, codepage_from, codepage_to)
    input = tostring(input or '');
    local length = string.len(input);
    local buffer = ffi.new('char['.. length .. ']');
    ffi.copy(buffer, input);

    local wchar_Length = ffi.C.MultiByteToWideChar(932, 0, buffer, -1, nil, 0);
    local wBuffer = ffi.new('wchar_t['.. wchar_Length .. ']');
    ffi.C.MultiByteToWideChar(codepage_from, 0, buffer, -1, wBuffer, wchar_Length);

    local char_length = ffi.C.WideCharToMultiByte(65001, 0, wBuffer, -1, nil, 0, 0)
    local uBuffer = ffi.new('char['.. char_length .. ']');

    ffi.C.WideCharToMultiByte(codepage_to, 0, wBuffer, -1, uBuffer, char_length, 0);

    encoding_report.source_length = length;
    encoding_report.wchar_Length = wchar_Length;
    encoding_report.char_length = char_length;

    return ffi.string(uBuffer);
end

function exports:ShiftJIS_To_UTF8(input)
    return Convert_String(input, 932, 65001);
end

function exports:UTF8_To_ShiftJIS(input)
    return Convert_String(input, 65001, 932);
end

return exports;