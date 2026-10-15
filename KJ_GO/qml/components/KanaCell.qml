import QtQuick
import "../theme"

Rectangle {
    id: root
    property string kana: "あ"
    property string romaji: "a"
    property string mastery: "unlearned"
    property bool dimmed: false
    signal activated()

    implicitWidth: 72
    implicitHeight: 64
    radius: Theme.radiusMd
    color: mastery === "mastered" ? Theme.primary : "transparent"
    border.width: mastery === "mastered" ? 0 : 1
    border.color: Theme.line
    opacity: dimmed ? 0.2 : 1
    scale: hover.hovered && !dimmed ? 1.06 : 1
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 8
        z: -1
        radius: Theme.radiusMd
        color: Qt.rgba(0.11, 0.106, 0.098, root.mastery === "mastered" ? 0 : (hover.hovered ? 0.16 : 0))
    }

    Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -8
        text: root.kana
        color: root.mastery === "mastered" ? Theme.primaryFg : Theme.text
        font.family: Theme.fontDisplay
        font.pixelSize: Theme.kanaCell
        font.bold: true
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        width: Math.max(0, parent.width - 8)
        horizontalAlignment: Text.AlignHCenter
        fontSizeMode: Text.HorizontalFit
        minimumPixelSize: 8
        text: root.romaji.toUpperCase()
        color: root.mastery === "mastered" ? Qt.rgba(Theme.primaryFg.r, Theme.primaryFg.g, Theme.primaryFg.b, 0.7) : Theme.textMuted
        font.family: Theme.fontBody
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: root.romaji.length > 3 ? 0.2 : 1.6
    }
    Rectangle {
        visible: root.mastery === "fuzzy"
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 18
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        height: 2
        color: Theme.accent
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.activated() }
}
