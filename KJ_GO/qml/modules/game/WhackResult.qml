import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    signal again()
    signal fresh()

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
            text: whackMole.perfect ? "全部打中" : "这一局"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 40
            font.bold: true
        }

        Row {
            spacing: 32
            Column {
                spacing: 4
                Text {
                    text: root.clockText(whackMole.seconds)
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
                    text: whackMole.hits
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "命中"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
            Column {
                spacing: 4
                Text {
                    text: whackMole.wrongTaps
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "打错"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
            Column {
                spacing: 4
                Text {
                    text: whackMole.escapes
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 28
                    font.bold: true
                }
                Text { text: "漏掉"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 12 }
            }
        }

        Text {
            text: "漏掉的词"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 2
        }

        Text {
            visible: whackMole.recap.length === 0
            text: "没有漏掉的词。"
            color: Theme.textMuted
            font.family: Theme.fontBody
            font.pixelSize: 14
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: whackMole.recap.length > 0
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
                    model: whackMole.recap
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
                    text: "换一批词"
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                HoverHandler { id: replayHover }
                TapHandler { onTapped: root.fresh() }
            }
        }
    }
}
