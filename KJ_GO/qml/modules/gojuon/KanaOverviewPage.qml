import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property bool katakana: false
    signal openDetail(string kana, string romaji)
    readonly property var kanaRows: [
        ["あ", "い", "う", "え", "お"],
        ["か", "き", "く", "け", "こ"],
        ["さ", "し", "す", "せ", "そ"],
        ["た", "ち", "つ", "て", "と"],
        ["な", "に", "ぬ", "ね", "の"],
        ["は", "ひ", "ふ", "へ", "ほ"],
        ["ま", "み", "む", "め", "も"],
        ["や", "ゆ", "よ"],
        ["ら", "り", "る", "れ", "ろ"],
        ["わ", "を", "ん"]
    ]
    readonly property var romajiRows: [
        ["a", "i", "u", "e", "o"], ["ka", "ki", "ku", "ke", "ko"],
        ["sa", "shi", "su", "se", "so"], ["ta", "chi", "tsu", "te", "to"],
        ["na", "ni", "nu", "ne", "no"], ["ha", "hi", "fu", "he", "ho"],
        ["ma", "mi", "mu", "me", "mo"], ["ya", "yu", "yo"],
        ["ra", "ri", "ru", "re", "ro"], ["wa", "wo", "n"]
    ]
    Rectangle { anchors.fill: parent; color: Theme.bg }
    ColumnLayout {
        anchors.fill: parent; anchors.margins: 48; spacing: 28
        RowLayout {
            Layout.fillWidth: true; spacing: 20
            ColumnLayout { spacing: 5
                Text { text: "五十音図"; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: Theme.title; font.bold: true }
                Text { text: "清音 · 记忆映射总览"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: Theme.body }
            }
            Item { Layout.fillWidth: true }
            ColumnLayout { spacing: 8; Text { text: "文字体系"; color: Theme.textMuted; font.pixelSize: Theme.label; horizontalAlignment: Text.AlignRight; Layout.fillWidth: true } ScriptToggle { katakana: root.katakana; onChanged: root.katakana = katakana } }
        }
        RowLayout { Layout.fillWidth: true; spacing: 12
            Text { text: "行"; Layout.preferredWidth: 48; color: Theme.textMuted; font.pixelSize: Theme.label }
            Repeater { model: 5; delegate: Text { required property int index; text: ["あ", "い", "う", "え", "お"][index]; Layout.preferredWidth: 88; horizontalAlignment: Text.AlignHCenter; color: Theme.textMuted; font.family: Theme.fontDisplay; font.pixelSize: 16 } }
        }
        ColumnLayout { Layout.fillWidth: true; spacing: 10
            Repeater {
                model: root.kanaRows.length
                delegate: RowLayout {
                    id: kanaRow
                    required property int index
                    Layout.fillWidth: true
                    spacing: 12
                    Text { text: ["あ行", "か行", "さ行", "た行", "な行", "は行", "ま行", "や行", "ら行", "わ行"][kanaRow.index]; Layout.preferredWidth: 48; color: Theme.textMuted; font.pixelSize: 12; horizontalAlignment: Text.AlignRight }
                    Repeater {
                        model: 5
                        delegate: KanaCell {
                            id: cell
                            required property int index
                            readonly property bool filled: cell.index < root.kanaRows[kanaRow.index].length
                            visible: filled
                            Layout.fillWidth: true
                            Layout.preferredHeight: 70
                            kana: filled ? root.kanaRows[kanaRow.index][cell.index] : ""
                            romaji: filled ? root.romajiRows[kanaRow.index][cell.index] : ""
                            mastery: (kanaRow.index * 5 + cell.index) % 7 === 0 ? "mastered" : (kanaRow.index * 5 + cell.index) % 5 === 0 ? "learning" : "new"
                            onActivated: root.openDetail(kana, romaji)
                        }
                    }
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
