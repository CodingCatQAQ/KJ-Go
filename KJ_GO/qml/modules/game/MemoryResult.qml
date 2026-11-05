import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    signal again()
    signal replay()

    function clockText(total) {
        var minutes = Math.floor(total / 60)
        var secs = total % 60
        return minutes + ":" + (secs < 10 ? "0" : "") + secs
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 48
        anchors.rightMargin: 48
        anchors.topMargin: 36
        anchors.bottomMargin: 32
        spacing: 20

        Text {
            text: memoryMatch.perfect ? "一次对完" : "这一局"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 40
            font.bold: true
        }

        Row {
            spacing: 36
            Column {
                spacing: 4
                Text {
                    text: root.clockText(memoryMatch.seconds)
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "用时"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
            Column {
                spacing: 4
                Text {
                    text: memoryMatch.moves
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "步数"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
            Column {
                spacing: 4
                Text {
                    text: memoryMatch.misses
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "失误"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
        }

        Text {
            text: "本局词汇"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 2
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: recapColumn.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: recapColumn
                width: parent.width
                spacing: 10
                Repeater {
                    model: memoryMatch.recap
                    delegate: Row {
                        required property var modelData
                        width: recapColumn.width
                        spacing: 20
                        Text {
                            width: 200
                            text: modelData.glyph
                            color: Theme.text
                            font.family: Theme.fontDisplay
                            font.pixelSize: 18
                            elide: Text.ElideRight
                        }
                        Text {
                            width: Math.max(0, recapColumn.width - 220)
                            text: modelData.gloss
                            color: Theme.textMuted
                            font.family: Theme.fontBody
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 12
            Rectangle {
                width: againLabel.implicitWidth + 36
                height: 40
                radius: Theme.radiusMd
                color: "transparent"
                border.width: 1
                border.color: againHover.hovered ? Theme.text : Theme.line
                Text {
                    id: againLabel
                    anchors.centerIn: parent
                    text: "再来一局"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                HoverHandler { id: againHover }
                TapHandler { onTapped: root.again() }
            }
            Rectangle {
                width: replayLabel.implicitWidth + 36
                height: 40
                radius: Theme.radiusMd
                color: "transparent"
                border.width: 1
                border.color: replayHover.hovered ? Theme.text : Theme.line
                Text {
                    id: replayLabel
                    anchors.centerIn: parent
                    text: "再练这组"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                HoverHandler { id: replayHover }
                TapHandler { onTapped: root.replay() }
            }
        }
    }
}
