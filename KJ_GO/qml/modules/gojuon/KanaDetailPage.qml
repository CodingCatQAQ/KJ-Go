import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property bool katakana: false
    property string romaji: "a"
    property string mastery: "new"
    property bool weak: false
    signal back()
    signal step(int direction)
    signal markWeak()

    readonly property var entry: KanaCatalog.find(katakana, romaji)
    readonly property string statusLabel: mastery === "mastered" ? "已掌握" : mastery === "learning" ? "正在学" : "未学"

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 32
        anchors.leftMargin: 48
        anchors.rightMargin: 48

        RowLayout {
            Layout.fillWidth: true
            Row {
                spacing: 8
                Text { text: "←"; color: Theme.textMuted; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "返回总览"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Kbd { text: "Esc"; anchors.verticalCenter: parent.verticalCenter }
                TapHandler { onTapped: root.back() }
            }
            Item { Layout.fillWidth: true }
            Row {
                spacing: 8
                Kbd { text: "←" }
                Kbd { text: "→" }
                Text { text: "切换假名"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 1; height: 12; color: Theme.line; anchors.verticalCenter: parent.verticalCenter }
                Kbd { text: "Tab" }
                Text { text: "平 / 片"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
            }
        }

        Item { Layout.fillHeight: true; Layout.preferredHeight: 12 }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 28

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: "transparent"
                border.width: 1
                border.color: hoverPrev.hovered ? Theme.text : Theme.line
                Text { anchors.centerIn: parent; text: "‹"; color: hoverPrev.hovered ? Theme.text : Theme.textMuted; font.pixelSize: 22 }
                HoverHandler { id: hoverPrev }
                TapHandler { onTapped: root.step(-1) }
            }

            Rectangle {
                width: 560
                implicitHeight: card.implicitHeight
                radius: 12
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 10
                    z: -1
                    radius: 12
                    color: Qt.rgba(0.11, 0.106, 0.098, 0.08)
                }

                Column {
                    id: card
                    width: parent.width - 96
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 32
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    spacing: 0

                    Row {
                        width: parent.width
                        Text {
                            text: (root.entry ? root.entry.label : "") + "  ·  " + (root.entry ? KanaCatalog.columnLabels[root.entry.column] : "")
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 11
                            font.letterSpacing: 1.8
                        }
                        Item { width: parent.width - 220; height: 1 }
                        Text {
                            text: KanaCatalog.pad2(KanaCatalog.position(root.romaji)) + "  /  " + KanaCatalog.total()
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        topPadding: 8
                        text: root.entry ? root.entry.char : ""
                        color: Theme.text
                        font.family: Theme.fontDisplay
                        font.pixelSize: Theme.kanaHero
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.romaji.toUpperCase()
                        color: Theme.text
                        font.family: Theme.fontBody
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 6
                    }
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        implicitWidth: statusText.implicitWidth + 16
                        implicitHeight: 22
                        radius: 2
                        color: root.mastery === "mastered" ? Theme.primary : "transparent"
                        border.width: root.mastery === "mastered" ? 0 : 1
                        border.color: root.mastery === "learning" ? Theme.accent : Theme.line
                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: root.statusLabel
                            color: root.mastery === "mastered" ? Theme.primaryFg : root.mastery === "learning" ? Theme.accent : Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }
                    }

                    Item { width: 1; height: 28 }

                    Row {
                        width: parent.width
                        height: 88
                        Rectangle { width: parent.width; height: 1; anchors.top: parent.top; color: Theme.border }
                        Rectangle { width: parent.width; height: 1; anchors.bottom: parent.bottom; color: Theme.border }
                        Row {
                            width: parent.width / 2 - 12
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "平假名 · HIRAGANA"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.2; font.family: Theme.fontBody; anchors.verticalCenter: parent.verticalCenter }
                            Item { width: 12; height: 1 }
                            Text {
                                text: root.entry ? root.entry.hira : ""
                                color: root.katakana ? Theme.primary : Theme.text
                                font.family: Theme.fontDisplay
                                font.pixelSize: Theme.kanaPair
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        Rectangle { x: parent.width / 2; width: 1; height: 56; anchors.verticalCenter: parent.verticalCenter; color: Theme.border }
                        Row {
                            x: parent.width / 2 + 24
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 16
                            Text { text: "片假名 · KATAKANA"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.2; font.family: Theme.fontBody; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: root.entry ? root.entry.kata : ""
                                color: root.katakana ? Theme.text : Theme.primary
                                font.family: Theme.fontDisplay
                                font.pixelSize: Theme.kanaPair
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    Item { width: 1; height: 20 }
                    Row {
                        width: parent.width
                        spacing: 16
                        Text { text: "联想"; color: Theme.accent; font.family: Theme.fontBody; font.pixelSize: 10; font.bold: true; font.letterSpacing: 2 }
                        Text {
                            width: parent.width - 48
                            wrapMode: Text.WordWrap
                            text: root.entry ? root.entry.mnemonic : ""
                            color: Theme.text
                            font.family: Theme.fontBody
                            font.pixelSize: 14
                            lineHeight: 1.5
                        }
                    }

                    Item { width: 1; height: 28 }
                    Row {
                        width: parent.width
                        spacing: 12
                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: 48
                            radius: Theme.radiusMd
                            color: Theme.primary
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: "听发音"; color: Theme.primaryFg; font.family: Theme.fontBody; font.pixelSize: 14; font.bold: true }
                                Kbd { text: "P" }
                            }
                        }
                        Rectangle {
                            width: (parent.width - 12) / 2
                            height: 48
                            radius: Theme.radiusMd
                            color: root.weak ? "transparent" : (weakHover.hovered ? Theme.accent : "transparent")
                            border.width: 1
                            border.color: root.weak ? Theme.line : Theme.accent
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: root.weak ? "已加入弱项队列" : "我记不住"
                                    color: root.weak ? Theme.textMuted : (weakHover.hovered ? Theme.primaryFg : Theme.accent)
                                    font.family: Theme.fontBody
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }
                            HoverHandler { id: weakHover; enabled: !root.weak }
                            TapHandler { enabled: !root.weak; onTapped: root.markWeak() }
                        }
                    }
                }
            }

            Rectangle {
                width: 44
                height: 44
                radius: 22
                color: "transparent"
                border.width: 1
                border.color: hoverNext.hovered ? Theme.text : Theme.line
                Text { anchors.centerIn: parent; text: "›"; color: hoverNext.hovered ? Theme.text : Theme.textMuted; font.pixelSize: 22 }
                HoverHandler { id: hoverNext }
                TapHandler { onTapped: root.step(1) }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
