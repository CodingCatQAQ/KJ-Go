import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property bool katakana: false
    signal openDetail(string kana, string romaji)
    readonly property var hiragana: ["あ", "か", "さ", "た", "な", "は", "ま", "や", "ら", "わ"]
    readonly property var katakanaRow: ["ア", "カ", "サ", "タ", "ナ", "ハ", "マ", "ヤ", "ラ", "ワ"]
    readonly property var romajiRow: ["a", "ka", "sa", "ta", "na", "ha", "ma", "ya", "ra", "wa"]
    readonly property var indices: {
        var list = []
        for (var i = 0; i < 50; ++i) {
            if (i % 5 === 0 && i % 7 !== 0)
                list.push(i)
        }
        return list
    }

    Rectangle { anchors.fill: parent; color: Theme.bg }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 40
        spacing: 24
        Column {
            spacing: 4
            Text { text: "弱项队列"; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: Theme.title; font.bold: true }
            Text { text: "学习中 · " + root.indices.length; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: Theme.body }
        }
        GridLayout {
            columns: 4
            rowSpacing: 10
            columnSpacing: 10
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            Repeater {
                model: root.indices
                delegate: KanaCell {
                    required property int modelData
                    kana: (root.katakana ? root.katakanaRow : root.hiragana)[modelData % 10]
                    romaji: root.romajiRow[modelData % 10]
                    mastery: "learning"
                    onActivated: root.openDetail(kana, romaji)
                }
            }
        }
        Item { Layout.fillHeight: true }
    }
}
