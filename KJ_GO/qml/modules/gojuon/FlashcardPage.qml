import QtQuick
import QtQuick.Layouts
import "../../theme"
import "../../components"

Item {
    id: root
    property var mastery: ({})
    property var weakList: []
    signal rate(string romaji, int score)
    signal exit()

    property var queue: []
    property int index: 0
    property bool flipped: false
    property int forgot: 0
    property int fuzzy: 0
    property int known: 0

    readonly property bool finished: queue.length === 0 || index >= queue.length
    readonly property string currentRomaji: queue.length === 0 ? "" : queue[Math.min(index, queue.length - 1)]
    readonly property var entry: currentRomaji ? KanaCatalog.find(false, currentRomaji) : null

    function restart() {
        index = 0
        flipped = false
        forgot = 0
        fuzzy = 0
        known = 0
    }

    function choose(score) {
        if (!flipped || finished || !currentRomaji)
            return
        rate(currentRomaji, score)
        if (score === 1)
            forgot += 1
        else if (score === 2)
            fuzzy += 1
        else
            known += 1
        flipped = false
        index += 1
    }

    Component.onCompleted: queue = KanaCatalog.reviewQueue(mastery, weakList)

    Rectangle { anchors.fill: parent; color: Theme.bg }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 32
        anchors.bottomMargin: 32
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "今日复习 · REVIEW"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.2
            }
            Text {
                text: KanaCatalog.pad2(Math.min(root.index + 1, Math.max(root.queue.length, 1)))
                color: Theme.text
                font.family: Theme.fontBody
                font.pixelSize: 14
                font.bold: true
            }
            Text {
                text: " / " + root.queue.length
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 14
            }
            Item { Layout.fillWidth: true }
            Row {
                spacing: 8
                Text { text: "退出"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                Kbd { text: "Esc"; anchors.verticalCenter: parent.verticalCenter }
                Text { text: "×"; color: Theme.textMuted; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                TapHandler { onTapped: root.exit() }
            }
        }

        Row {
            Layout.fillWidth: true
            height: 2
            spacing: 4
            Repeater {
                model: root.queue.length
                delegate: Rectangle {
                    required property int index
                    width: root.queue.length > 0 ? (parent.width - (root.queue.length - 1) * 4) / root.queue.length : 0
                    height: 2
                    color: index < root.index ? Theme.accent : Theme.border
                }
            }
        }

        Item { Layout.fillHeight: true }

        Column {
            visible: root.finished
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "終"
                color: Theme.text
                font.family: Theme.fontDisplay
                font.pixelSize: 128
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SESSION COMPLETE"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 12
                font.letterSpacing: 3
            }
            Item { width: 1; height: 24 }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 48
                Column {
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.forgot; font.pixelSize: 28; font.bold: true; color: Theme.text; font.family: Theme.fontBody }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "忘了"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody }
                }
                Column {
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.fuzzy; font.pixelSize: 28; font.bold: true; color: Theme.text; font.family: Theme.fontBody }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "模糊"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody }
                }
                Column {
                    spacing: 4
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.known; font.pixelSize: 28; font.bold: true; color: Theme.text; font.family: Theme.fontBody }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "会了"; color: Theme.textMuted; font.pixelSize: 12; font.family: Theme.fontBody }
                }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: restartRow.implicitWidth + 40
                height: 44
                radius: Theme.radiusMd
                color: "transparent"
                border.width: 1
                border.color: restartHover.hovered ? Theme.text : Theme.line
                Row {
                    id: restartRow
                    anchors.centerIn: parent
                    spacing: 8
                    Text { text: "再来一轮"; color: Theme.text; font.family: Theme.fontBody; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                    Kbd { text: "Enter"; anchors.verticalCenter: parent.verticalCenter }
                }
                HoverHandler { id: restartHover }
                TapHandler { onTapped: root.restart() }
            }
        }

        Column {
            visible: !root.finished
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 28

            Item {
                id: scene
                width: 400
                height: 440
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    id: inner
                    anchors.fill: parent
                    transform: Rotation {
                        id: spin
                        origin.x: inner.width / 2
                        origin.y: inner.height / 2
                        axis { x: 0; y: 1; z: 0 }
                        angle: root.flipped ? 180 : 0
                        Behavior on angle { NumberAnimation { duration: Theme.durFlip; easing.type: Easing.InOutCubic } }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: spin.angle < 90 || spin.angle > 270
                        radius: 12
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 28; text: "平假名 · FRONT"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 2.2; font.family: Theme.fontBody }
                        Text { anchors.centerIn: parent; text: root.entry ? root.entry.hira : ""; color: Theme.text; font.family: Theme.fontDisplay; font.pixelSize: Theme.kanaHero; font.bold: true }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 28; text: "它读作什么？"; color: Theme.textMuted; font.pixelSize: 11; font.letterSpacing: 1.4; font.family: Theme.fontBody }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: spin.angle >= 90 && spin.angle <= 270
                        radius: 12
                        color: Theme.surface
                        border.width: 1
                        border.color: Theme.border
                        transform: Rotation {
                            origin.x: width / 2
                            origin.y: height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: 180
                        }
                        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2; color: Theme.primary }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 28; text: "答案 · BACK"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 2.2; font.family: Theme.fontBody }
                        Column {
                            anchors.centerIn: parent
                            spacing: 20
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.currentRomaji.toUpperCase()
                                color: Theme.text
                                font.family: Theme.fontBody
                                font.pixelSize: 48
                                font.letterSpacing: 8
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 28
                                Column {
                                    spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.hira : ""; font.family: Theme.fontDisplay; font.pixelSize: 56; font.bold: true; color: Theme.text }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "平假名"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.6; font.family: Theme.fontBody }
                                }
                                Rectangle { width: 1; height: 64; color: Theme.line }
                                Column {
                                    spacing: 8
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.entry ? root.entry.kata : ""; font.family: Theme.fontDisplay; font.pixelSize: 56; font.bold: true; color: Theme.primary }
                                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "片假名"; color: Theme.textMuted; font.pixelSize: 10; font.letterSpacing: 1.6; font.family: Theme.fontBody }
                                }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 24
                            width: parent.width - 48
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.WordWrap
                            text: root.entry ? root.entry.mnemonic : ""
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 12
                        }
                    }

                    TapHandler { onTapped: root.flipped = !root.flipped }
                }
            }

            Item {
                width: 400
                height: 64
                anchors.horizontalCenter: parent.horizontalCenter
                Text {
                    visible: !root.flipped
                    anchors.centerIn: parent
                    text: "点击卡片翻面"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Row {
                    visible: root.flipped
                    anchors.centerIn: parent
                    spacing: 12
                    Rectangle {
                        width: 120
                        height: 64
                        radius: Theme.radiusMd
                        color: forgotHover.hovered ? Theme.accent : "transparent"
                        border.width: 1
                        border.color: Theme.accent
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "1  忘了"; color: forgotHover.hovered ? Theme.primaryFg : Theme.accent; font.pixelSize: 14; font.bold: true; font.family: Theme.fontBody }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "< 1 分钟"; color: forgotHover.hovered ? Theme.primaryFg : Theme.accent; font.pixelSize: 10; font.family: Theme.fontBody; opacity: 0.7 }
                        }
                        HoverHandler { id: forgotHover }
                        TapHandler { onTapped: root.choose(1) }
                    }
                    Rectangle {
                        width: 120
                        height: 64
                        radius: Theme.radiusMd
                        color: "transparent"
                        border.width: 1
                        border.color: fuzzyHover.hovered ? Theme.text : Theme.line
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "2  模糊"; color: Theme.text; font.pixelSize: 14; font.bold: true; font.family: Theme.fontBody }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "10 分钟"; color: Theme.textMuted; font.pixelSize: 10; font.family: Theme.fontBody }
                        }
                        HoverHandler { id: fuzzyHover }
                        TapHandler { onTapped: root.choose(2) }
                    }
                    Rectangle {
                        width: 120
                        height: 64
                        radius: Theme.radiusMd
                        color: Theme.primary
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "3  会了"; color: Theme.primaryFg; font.pixelSize: 14; font.bold: true; font.family: Theme.fontBody }
                            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "3 天"; color: Theme.primaryFg; font.pixelSize: 10; font.family: Theme.fontBody; opacity: 0.75 }
                        }
                        TapHandler { onTapped: root.choose(3) }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
