import QtQuick
import "../../theme"

Item {
    id: root
    signal openVocab()

    Column {
        anchors.centerIn: parent
        spacing: 28
        width: 420

        Text {
            text: "记忆配对"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.title
            font.bold: true
        }
        Text {
            width: 420
            wrapMode: Text.WordWrap
            text: "翻开单词和释义，对上同一条词就消掉，对不上就盖回去。同一条中文释义只留一个词。"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 14
            lineHeight: 1.5
        }
        Text {
            text: "现在有 " + memoryMatch.usableCount + " 个词可以上场。"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 13
        }

        Column {
            width: 420
            spacing: 12
            MemoryTierButton {
                title: "基础"
                side: 4
                onPicked: memoryMatch.start(4)
            }
            MemoryTierButton {
                title: "中等"
                side: 6
                onPicked: memoryMatch.start(6)
            }
            MemoryTierButton {
                title: "困难"
                side: 8
                onPicked: memoryMatch.start(8)
            }
        }

        Rectangle {
            visible: memoryMatch.usableCount < 8
            width: addLabel.implicitWidth + 36
            height: 40
            radius: Theme.radiusMd
            color: "transparent"
            border.width: 1
            border.color: addHover.hovered ? Theme.text : Theme.line
            Text {
                id: addLabel
                anchors.centerIn: parent
                text: "去添加词汇"
                color: Theme.text
                font.family: Theme.fontBody
                font.pixelSize: 14
            }
            HoverHandler { id: addHover }
            TapHandler { onTapped: root.openVocab() }
        }
    }
}
