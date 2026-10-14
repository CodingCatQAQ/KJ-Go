import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: control
    property bool katakana: false
    signal changed(bool katakana)
    spacing: 12

    component Segment: Rectangle {
        id: segment
        property string kana: ""
        property string label: ""
        property bool active: false
        signal picked()
        implicitWidth: body.implicitWidth + 28
        implicitHeight: 36
        radius: Theme.radiusSm
        color: active ? Theme.text : "transparent"

        Row {
            id: body
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: segment.kana
                color: segment.active ? Theme.bg : Theme.textMuted
                font.family: Theme.fontDisplay
                font.pixelSize: 18
                font.bold: true
            }
            Text {
                text: segment.label
                color: segment.active ? Theme.bg : Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        TapHandler {
            onTapped: {
                if (!segment.active)
                    segment.picked()
            }
        }
    }

    Rectangle {
        implicitWidth: segments.implicitWidth + 8
        implicitHeight: 44
        radius: Theme.radiusMd
        color: "transparent"
        border.width: 1
        border.color: Theme.line

        Row {
            id: segments
            anchors.centerIn: parent
            spacing: 0
            Segment {
                kana: "あ"
                label: "平假名"
                active: !control.katakana
                onPicked: control.changed(false)
            }
            Segment {
                kana: "ア"
                label: "片假名"
                active: control.katakana
                onPicked: control.changed(true)
            }
        }
    }

    Kbd {
        text: "Tab"
        Layout.alignment: Qt.AlignVCenter
    }
}
