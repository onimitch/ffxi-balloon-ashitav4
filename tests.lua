require('common')

local tests = T{}

tests.short = {
    'Can I look after an item?', 
    'アイテムを預けるクポ？',
}

tests.std = {
    'TODO', 
    [[モーグリの応援、
ちゃんと届いているクポ？　今、モグハウスは
弱い雷の力で満たされているクポ！]],
}

tests.std = {
    'TODO', 
    [[モーグリの応援、
ちゃんと届いているクポ？　今、モグハウスは
弱い雷の力で満たされているクポ！]],
}

tests.item = {
    'TODO', 
    [[池から]] .. string.char(0x1E,0x02) .. [[魚籠【堀ブナ】]] .. string.char(0x1E,0x01) .. [[を、畑で]] .. string.char(0x1E,0x02) .. [[ナットベイン]] .. string.char(0x1E,0x01) .. [[と
]] .. string.char(0x1E,0x02) .. [[デーツ]] .. string.char(0x1E,0x01) .. [[を用意してほしいクポ！]],
}

return tests