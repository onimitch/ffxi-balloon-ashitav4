require('common')

local defines = require('defines')
local cc = defines.chat_color_codes

local tests = T{}

tests.short = {
    'Test',
    'Can I look after an item?',
    'アイテムを預けるクポ？',
}

tests.item = {
    'Moogle',
    [[Please get me an ]] .. cc.item .. [[Orange Juice]] .. cc.standard ..
    [[ and some ]] .. cc.item .. [[Apple Pie]] .. cc.standard,
    [[池から]] .. cc.item .. [[魚籠【堀ブナ】]] .. cc.standard ..
    [[を、畑で]] .. cc.item .. [[ナットベイン]] .. cc.standard ..
    [[と]] .. cc.item .. [[デーツ]] .. cc.standard .. [[を用意してほしいクポ！]],
}

tests.crash1 = {
    'Crash Test',
    '',
    [[……。]],
}

tests.crash2 = {
    'Crash Test',
    '',
    [[…… ]],
}

tests.crash3 = {
    'Crash Test',
    '',
    [[……]],
}

tests.crash4 = {
    'Crash Test',
    '',
    [[...]],
}

tests.crash5 = {
    'Crash Test',
    '',
    [[...]],
}

tests.clip_issue1 = {
    'Makki-Chebukki',
    '',
    [[……。
プリッシュのおしおき、思いっきりやるもんなぁ～]],
}
tests.clip_issue2 = {
    'Kukki-Chebukki',
    '',
    [[……。
プリッシュのおしおき、遠慮ないもんなぁ～。]],
}
tests.clip_issue3 = {
    'Cherukiki',
    '',
    [[……。
プリッシュのおしおき、殺す気まんまんだもんなぁ～]],
}
tests.clip_issue4 = {
    'Makki-Chebukki',
    '',
    [[……。
あのさぁ、おいら思うんだけどさぁ。]],
}

tests.colors = {
    'Test',
    [[１]] .. cc.item .. [[Item]] .. cc.standard .. ', ' ..
    [[２]] .. cc.key_item .. [[Key item]] .. cc.standard .. ', ' ..
    [[３]] .. cc.blue .. [[Blue]] .. cc.standard .. ', ' ..
    [[４]] .. cc.magenta .. [[Equipment?]] .. cc.standard .. ', ' ..
    [[５]] .. cc.cyan .. [[Cyan]] .. cc.standard .. ', ' ..
    [[６]] .. cc.yellow .. [[Yellow]] .. cc.standard .. ', ' ..
    [[７]] .. cc.orange .. [[Orange]] .. cc.standard,

    [[１]] .. cc.item .. [[アイテム]] .. cc.standard .. ', ' ..
    [[２]] .. cc.key_item .. [[大事なもの]] .. cc.standard .. ', ' ..
    [[３]] .. cc.blue .. [[青]] .. cc.standard .. ', ' ..
    [[４]] .. cc.magenta .. [[装備？]] .. cc.standard .. ', ' ..
    [[５]] .. cc.cyan .. [[シアン色]] .. cc.standard .. ', ' ..
    [[６]] .. cc.yellow .. [[黄色]] .. cc.standard .. ', ' ..
    [[７]] .. cc.orange .. [[オレンジ色]] .. cc.standard
}

tests.long = {
    'Test',
    "Selh'teus proved that to us ten thousand years ago. Destruction is your destiny. You cannot escape what has already been decided.",
    [[お前のバッグ、
ゴブリンたちより、ずっと大きい。
それも当然、お前は伝説のゴウツバクリだからだ。
それでも足りない。それこそが伝説……。]],
}

tests.bahamut = {
    'Bahamut',
    "Selh'teus proved that to us ten thousand years ago. Destruction is your destiny. You cannot escape what has already been decided.",
    [[……なぁんて、な。
ガラでもねぇか、ヘヘッ。
じゃあ、さっそくつけ始めてくれ。
遅くとも夜中の1時ごろまでにはつけ終えてくれよ。]],
}

return tests