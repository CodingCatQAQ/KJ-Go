import QtQuick
import QtQuick.Layouts
import "../../theme"

Item {
    id: root
    property string setId: "ja-vocab"
    property bool running: true
    signal openVocab()

    function clockText(total) {
        var minutes = Math.floor(total / 60)
        var secs = total % 60
        return minutes + ":" + (secs < 10 ? "0" : "") + secs
    }

    Binding {
        target: whackMole
        property: "setId"
        value: root.setId
        restoreMode: Binding.RestoreNone
    }

    onRunningChanged: whackMole.setRunning(running)
    Component.onCompleted: whackMole.setRunning(running)

    Rectangle { anchors.fill: parent; color: Theme.bg }

    WhackSetup {
        anchors.fill: parent
        visible: whackMole.phase === "setup"
        onOpenVocab: root.openVocab()
    }

    Item {
        anchors.fill: parent
        visible: whackMole.phase === "playing"

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 36
            anchors.rightMargin: 36
            anchors.topMargin: 24
            anchors.bottomMargin: 20
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "第 " + whackMole.promptNumber + " / " + whackMole.promptTotal + " 题"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 12
                    font.letterSpacing: 1.4
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "命中 " + whackMole.hits
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item { width: 20; height: 1 }
                Text {
                    text: "打错 " + whackMole.wrongTaps
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item { width: 20; height: 1 }
                Text {
                    text: "漏掉 " + whackMole.escapes
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
                Item { width: 20; height: 1 }
                Text {
                    text: root.clockText(whackMole.seconds)
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: true
                }
                Item { width: 28; height: 1 }
                Text {
                    text: "结束"
                    color: endHover.hovered ? Theme.text : Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    HoverHandler { id: endHover }
                    TapHandler { onTapped: whackMole.endRound() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 112
                radius: Theme.radiusXl
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                Column {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 6
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: whackMole.moleFace === "word" ? "释义" : "单词"
                        color: Theme.textMuted
                        font.family: Theme.fontBody
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: whackMole.promptText
                        color: Theme.text
                        font.family: whackMole.moleFace === "word" ? Theme.fontBody : Theme.fontDisplay
                        font.pixelSize: whackMole.moleFace === "word" ? 28 : 40
                        font.bold: true
                    }
                }
            }

            WhackBoard {
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }

    WhackResult {
        anchors.fill: parent
        visible: whackMole.phase === "finished"
        onAgain: whackMole.replay()
        onFresh: whackMole.again()
    }
}
