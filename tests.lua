require('common')

local defines = require('defines')
local cc = defines.chat_color_codes

local tests = T{}

tests.short = {
    'Test',
    'Can I look after an item?', 
    'アイテムを預けるクポ？',
}

tests.std = {
    'Test',
    'TODO', 
    [[モーグリの応援、
ちゃんと届いているクポ？　今、モグハウスは
弱い雷の力で満たされているクポ！]],
}

tests.item = {
    'Test',
    'TODO', 
    [[池から]] .. cc.item .. [[魚籠【堀ブナ】]] .. cc.standard .. 
    [[を、畑で]] .. cc.item .. [[ナットベイン]] .. cc.standard .. 
    [[と]] .. cc.item .. [[デーツ]] .. cc.standard .. [[を用意してほしいクポ！]],
}

tests.long = {
    'Test',
    'TODO',
    [[お前のバッグ、
ゴブリンたちより、ずっと大きい。
それも当然、お前は伝説のゴウツバクリだからだ。
それでも足りない。それこそが伝説……。]],
}

tests.long2 = {
    'Test',
    'TODO',
    [[……なぁんて、な。
ガラでもねぇか、ヘヘッ。
じゃあ、さっそくつけ始めてくれ。
遅くとも夜中の1時ごろまでにはつけ終えてくれよ。]],
}

tests.baha = {
    'Bahamut',
    "Selh'teus proved that to us ten thousand years ago. Destruction is your destiny. You cannot escape what has already been decided.",
    [[……なぁんて、な。
ガラでもねぇか、ヘヘッ。
じゃあ、さっそくつけ始めてくれ。
遅くとも夜中の1時ごろまでにはつけ終えてくれよ。]],
}

return tests