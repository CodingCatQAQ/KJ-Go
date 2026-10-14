pragma Singleton
import QtQuick

QtObject {
    readonly property var vowels: ["a", "ya", "eo", "yeo", "o", "yo", "u", "yu", "eu", "i"]
    readonly property var vowelGlyphs: ["ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ"]
    readonly property var columnLabels: ["ㅏ", "ㅑ", "ㅓ", "ㅕ", "ㅗ", "ㅛ", "ㅜ", "ㅠ", "ㅡ", "ㅣ"]
    readonly property var medialIndex: [0, 2, 4, 6, 8, 12, 13, 17, 18, 20]
    readonly property var initials: [
        { index: 0, group: "g", short: "ㄱ" },
        { index: 2, group: "n", short: "ㄴ" },
        { index: 3, group: "d", short: "ㄷ" },
        { index: 5, group: "r", short: "ㄹ" },
        { index: 6, group: "m", short: "ㅁ" },
        { index: 7, group: "b", short: "ㅂ" },
        { index: 9, group: "s", short: "ㅅ" },
        { index: 11, group: "ng", short: "ㅇ" },
        { index: 12, group: "j", short: "ㅈ" },
        { index: 14, group: "ch", short: "ㅊ" },
        { index: 15, group: "k", short: "ㅋ" },
        { index: 16, group: "t", short: "ㅌ" },
        { index: 17, group: "p", short: "ㅍ" },
        { index: 18, group: "h", short: "ㅎ" }
    ]

    readonly property var rows: buildRows()

    function buildRows() {
        var built = []
        for (var r = 0; r < initials.length; ++r) {
            var glyphs = []
            var romaji = []
            var onset = initials[r].short === "ㅇ" ? "" : initials[r].group
            for (var c = 0; c < medialIndex.length; ++c) {
                glyphs.push(String.fromCharCode(0xAC00 + (initials[r].index * 21 + medialIndex[c]) * 28))
                romaji.push(onset + vowels[c])
            }
            built.push({
                group: initials[r].group,
                label: initials[r].short + " 行",
                short: initials[r].short,
                glyphs: glyphs,
                romaji: romaji
            })
        }
        return built
    }

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

    function find(romaji) {
        for (var r = 0; r < rows.length; ++r) {
            var row = rows[r]
            for (var c = 0; c < row.romaji.length; ++c) {
                if (row.romaji[c] !== romaji)
                    continue
                return {
                    char: row.glyphs[c],
                    consonant: row.short,
                    vowel: vowelGlyphs[c],
                    romaji: romaji,
                    label: row.label,
                    column: c,
                    mnemonic: ""
                }
            }
        }
        return null
    }

    function position(romaji) {
        return romajiList().indexOf(romaji) + 1
    }

    function total() {
        return romajiList().length
    }

    function pad3(value) {
        var text = "" + value
        while (text.length < 3)
            text = "0" + text
        return text
    }
}
