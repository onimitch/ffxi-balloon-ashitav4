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

tests.clip_issue = {
    'Makki-Chebukki',
    [[...
This line used to get clipped.]],
    [[……。
プリッシュのおしおき、思いっきりやるもんなぁ〜]],
}

tests.unknown = {
    '???',
    'Unknown speaker...',
    [[不思議な人物……。]],
}

tests.homepoint = {
    '',
    'A home point can be set as a spot for you to return to Vana\'diel when you have been knocked out. You can also use a home point to teleport to other home points.',
    [[ここではホームポイントを利用して、
戦闘不能時の帰って来る位置の設定や
他のホームポイントへのワープができます。]],
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

tests.bahamut = {
    'Bahamut',
    "Selh'teus proved that to us ten thousand years ago. Destruction is your destiny. You cannot escape what has already been decided.",
    [[生ける神の力を授けても、
おまえたち人を救うことはできん。
おまえたちは既に死んでいる。
死によって朽ち果てた躯にすぎない。]],
}

tests.punctuation_wrap = {
    'Test',
    "--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--" ..
    "testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--" ..
    "foo-----testing... foo-- testing -- foo --end--",
    "--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--" ..
    "testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--testing...foo--" ..
    "foo-----testing... foo-- testing -- foo --end--",
}

return tests