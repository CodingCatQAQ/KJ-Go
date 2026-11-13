import QtQuick
import "../../theme"

Item {
    id: root
    signal openVocab()
    property string direction: "gloss"

    Column {
        anchors.centerIn: parent
        spacing: 28
        width: 420

        Text {
            text: "词汇打地鼠"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: Theme.title
            font.bold: true
        }
        Text {
            width: 420
            wrapMode: Text.WordWrap
            text: "看上面的题，打中洞里对应的那一只。打错会缩回去，题还在。正确的没打到，这题算漏掉。"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 14
            lineHeight: 1.5
        }

        Row {
            width: 420
            spacing: 12
            Rectangle {
                width: 204
                height: 44
                radius: Theme.radiusMd
                color: root.direction === "gloss" ? Theme.muted : Theme.surface
                border.width: 1
                border.color: root.direction === "gloss" || glossHover.hovered ? Theme.text : Theme.border
                Text {
                    anchors.centerIn: parent
                    text: "看释义，打单词"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: root.direction === "gloss"
                }
                HoverHandler { id: glossHover }
                TapHandler { onTapped: root.direction = "gloss" }
            }
            Rectangle {
                width: 204
                height: 44
                radius: Theme.radiusMd
                color: root.direction === "glyph" ? Theme.muted : Theme.surface
                border.width: 1
                border.color: root.direction === "glyph" || glyphHover.hovered ? Theme.text : Theme.border
                Text {
                    anchors.centerIn: parent
                    text: "看单词，打释义"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: root.direction === "glyph"
                }
                HoverHandler { id: glyphHover }
                TapHandler { onTapped: root.direction = "glyph" }
            }
        }

        Text {
            text: "现在有 " + whackMole.usableCount + " 个词可以上场。"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 13
        }

        Column {
            width: 420
            spacing: 12
            MemoryTierButton {
                title: "从容"
                caption: "8 题 · 同时 1 只 · 停 1.6 秒"
                needCount: 4
                poolCount: whackMole.usableCount
                onPicked: whackMole.start("calm", root.direction)
            }
            MemoryTierButton {
                title: "紧凑"
                caption: "12 题 · 同时 2 只 · 停 1.1 秒"
                needCount: 4
                poolCount: whackMole.usableCount
                onPicked: whackMole.start("brisk", root.direction)
            }
            MemoryTierButton {
                title: "急促"
                caption: "16 题 · 同时 3 只 · 停 0.75 秒"
                needCount: 4
                poolCount: whackMole.usableCount
                onPicked: whackMole.start("rush", root.direction)
            }
        }

        Rectangle {
            visible: whackMole.usableCount < 4
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
