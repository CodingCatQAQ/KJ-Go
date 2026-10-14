import QtQuick
import "../../theme"

Item {
    property string kana: "あ"
    property string romaji: "a"

    Rectangle { anchors.fill: parent; color: Theme.bg }
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 40
        spacing: 8
        Text { text: "单字详情"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: Theme.body }
        Text { text: kana; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: Theme.kanaHero }
        Text {
            text: romaji.toUpperCase()
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: Theme.kanaPair
            font.letterSpacing: 4
        }
    }
}
