pragma Singleton
import QtQuick

QtObject {
    readonly property var vowels: ["a", "i", "u", "e", "o"]
    readonly property var columnLabels: ["あ段", "い段", "う段", "え段", "お段"]
    readonly property var rows: [
        { group: "a", label: "あ行", short: "あ", hira: ["あ", "い", "う", "え", "お"], kata: ["ア", "イ", "ウ", "エ", "オ"], romaji: ["a", "i", "u", "e", "o"] },
        { group: "ka", label: "か行", short: "か", hira: ["か", "き", "く", "け", "こ"], kata: ["カ", "キ", "ク", "ケ", "コ"], romaji: ["ka", "ki", "ku", "ke", "ko"] },
        { group: "sa", label: "さ行", short: "さ", hira: ["さ", "し", "す", "せ", "そ"], kata: ["サ", "シ", "ス", "セ", "ソ"], romaji: ["sa", "shi", "su", "se", "so"] },
        { group: "ta", label: "た行", short: "た", hira: ["た", "ち", "つ", "て", "と"], kata: ["タ", "チ", "ツ", "テ", "ト"], romaji: ["ta", "chi", "tsu", "te", "to"] },
        { group: "na", label: "な行", short: "な", hira: ["な", "に", "ぬ", "ね", "の"], kata: ["ナ", "ニ", "ヌ", "ネ", "ノ"], romaji: ["na", "ni", "nu", "ne", "no"] },
        { group: "ha", label: "は行", short: "は", hira: ["は", "ひ", "ふ", "へ", "ほ"], kata: ["ハ", "ヒ", "フ", "ヘ", "ホ"], romaji: ["ha", "hi", "fu", "he", "ho"] },
        { group: "ma", label: "ま行", short: "ま", hira: ["ま", "み", "む", "め", "も"], kata: ["マ", "ミ", "ム", "メ", "モ"], romaji: ["ma", "mi", "mu", "me", "mo"] },
        { group: "ya", label: "や行", short: "や", hira: ["や", "", "ゆ", "", "よ"], kata: ["ヤ", "", "ユ", "", "ヨ"], romaji: ["ya", "", "yu", "", "yo"] },
        { group: "ra", label: "ら行", short: "ら", hira: ["ら", "り", "る", "れ", "ろ"], kata: ["ラ", "リ", "ル", "レ", "ロ"], romaji: ["ra", "ri", "ru", "re", "ro"] },
        { group: "wa", label: "わ行", short: "わ", hira: ["わ", "", "", "", "を"], kata: ["ワ", "", "", "", "ヲ"], romaji: ["wa", "", "", "", "wo"] },
        { group: "n", label: "ん", short: "ん", hira: ["ん", "", "", "", ""], kata: ["ン", "", "", "", ""], romaji: ["n", "", "", "", ""] }
    ]

    function romajiList() {
        var list = []
        for (var r = 0; r < rows.length; ++r) {
            var romaji = rows[r].romaji
            for (var c = 0; c < romaji.length; ++c) {
                if (romaji[c])
                    list.push(romaji[c])
            }
        }
        return list
    }

    function initialMastery() {
        var list = romajiList()
        var mastery = {}
        for (var i = 0; i < list.length; ++i)
            mastery[list[i]] = i < 15 ? "mastered" : i < 21 ? "learning" : "new"
        return mastery
    }

    function mnemonic(romaji) {
        var notes = {
            "a": "像一个人张开双臂喊「啊」——あ 里藏着十字和一个圈。",
            "i": "两根并排的小草，像发出「咿」时咧开的嘴角。",
            "u": "头顶一点、身体弯曲，像被打了一拳「呜」地弯腰。",
            "e": "像一位跳舞的人单脚着地，转身喊「诶」。",
            "o": "一个人提着球跑「哦」，右上角那一点是汗。",
            "ka": "像一把刀「卡」进木头里，右边那点是木屑。",
            "ki": "一把钥匙 key 的形状，开门「ki」。",
            "ku": "张开的鸟嘴「咕咕」叫，就是一个尖括号。",
            "sa": "像一个笑脸被斜切一刀，「萨」一下。",
            "shi": "一根钓鱼钩，钓到了「鱼」(shi)。",
            "ta": "左边是「t」，右边是「a」，合起来 ta。",
            "tsu": "一个微笑的嘴，配合「次」的口型。",
            "na": "一个人跪着祈祷，口中念「na」。",
            "ha": "右边像字母 h + a，ha ha 大笑。",
            "ma": "像妈妈的发髻，喊「妈」。",
            "ya": "像一头牦牛（yak）的角。",
            "ra": "一只兔子(rabbit)转身的样子。",
            "wa": "像一只张嘴的小狗「汪」。",
            "n": "一个小写 n 的手写体。"
        }
        return notes[romaji] || (romaji.toUpperCase() + " —— 写下你自己的联想，越荒诞越好记。")
    }

    function find(katakana, romaji) {
        for (var r = 0; r < rows.length; ++r) {
            var row = rows[r]
            for (var c = 0; c < row.romaji.length; ++c) {
                if (row.romaji[c] !== romaji)
                    continue
                var chars = katakana ? row.kata : row.hira
                return {
                    char: chars[c],
                    hira: row.hira[c],
                    kata: row.kata[c],
                    romaji: romaji,
                    label: row.label,
                    column: c,
                    mnemonic: mnemonic(romaji)
                }
            }
        }
        return null
    }

    function counts(mastery) {
        var total = 0
        var mastered = 0
        var learning = 0
        var fresh = 0
        for (var key in mastery) {
            total += 1
            if (mastery[key] === "mastered")
                mastered += 1
            else if (mastery[key] === "learning")
                learning += 1
            else
                fresh += 1
        }
        return { total: total, mastered: mastered, learning: learning, fresh: fresh }
    }

    function step(romaji, direction) {
        var list = romajiList()
        var index = list.indexOf(romaji)
        if (index < 0)
            return list[0]
        return list[(index + direction + list.length) % list.length]
    }

    function position(romaji) {
        var list = romajiList()
        return list.indexOf(romaji) + 1
    }

    function total() {
        return romajiList().length
    }

    function pad2(value) {
        return value < 10 ? "0" + value : "" + value
    }

    function reviewQueue(mastery, weak) {
        var all = romajiList()
        var learning = []
        var fresh = []
        for (var i = 0; i < all.length; ++i) {
            var romaji = all[i]
            if (weak.indexOf(romaji) >= 0)
                continue
            if (mastery[romaji] === "learning")
                learning.push(romaji)
            else if (mastery[romaji] === "new")
                fresh.push(romaji)
        }
        return weak.slice().concat(learning).concat(fresh).slice(0, 12)
    }
}
