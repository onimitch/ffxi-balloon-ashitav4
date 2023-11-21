local ffi = require('ffi');
ffi.cdef[[
    int MultiByteToWideChar(uint32_t CodePage, uint32_t dwFlags, char* lpMultiByteStr, int cbMultiByte, wchar_t* lpMultiByteStr, int32_t cchWideChar);
    int WideCharToMultiByte(uint32_t CodePage, uint32_t dwFlags, wchar_t* lpWideCharString, int32_t cchWideChar, char* lpMultiByteStr, int32_t cbMultiByte, char lpDefaultChar);
]]

local exports = T{};

-- function exports:ShiftJIS_To_UTF8(input)
--     input = tostring(input or '')
--     local length = input:len()
--     local buffer = ffi.new('char['.. length .. ']');
--     ffi.copy(buffer, input);
--     local wBuffer = ffi.new('wchar_t['.. length .. ']');
--     ffi.C.MultiByteToWideChar(932, 0, buffer, -1, wBuffer, length);
--     ffi.C.WideCharToMultiByte(65001, 0, wBuffer, -1, buffer, length, 0);
--     return ffi.string(buffer);
-- end

encoding_report = {}
encoding_report.source_length = 0
encoding_report.utf16size = 0
encoding_report.utf8size = 0

function exports:ShiftJIS_To_UTF8(input)
    input = tostring(input or '')
    local length = string.len(input)
    local buffer = ffi.new('char['.. length .. ']');
    ffi.copy(buffer, input);

    local utf16size = ffi.C.MultiByteToWideChar(932, 0, buffer, -1, nil, 0);
    local wBuffer = ffi.new('wchar_t['.. utf16size .. ']');
    ffi.C.MultiByteToWideChar(932, 0, buffer, -1, wBuffer, utf16size);

    local utf8size = ffi.C.WideCharToMultiByte(65001, 0, wBuffer, -1, nil, 0, 0)
    local uBuffer = ffi.new('char['.. length .. ']');

    ffi.C.WideCharToMultiByte(65001, 0, wBuffer, -1, uBuffer, utf8size, 0);

    encoding_report.source_length = length
    encoding_report.utf16size = utf16size
    encoding_report.utf8size = utf8size

    return ffi.string(uBuffer);
end

function exports:UTF8_To_ShiftJIS(input)
    input = tostring(input or '')
    local buffer = ffi.new('char[4096]');
    ffi.copy(buffer, input);
    local wBuffer = ffi.new("wchar_t[4096]");
    ffi.C.MultiByteToWideChar(65001, 0, buffer, -1, wBuffer, 4096);
    ffi.C.WideCharToMultiByte(932, 0, wBuffer, -1, buffer, 4096, 0);
    return ffi.string(buffer);
end

return exports;