import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"
import "../modules/gojuon"

Item {
    id: root
    property int currentModule: 0
    Rectangle { anchors.fill: parent; color: Theme.bg }
    AppTopBar { id: topBar; anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; currentIndex: root.currentModule; onNavigate: root.currentModule = index; onToggleTheme: Theme.dark = !Theme.dark }
    Rectangle { anchors.top: topBar.bottom; anchors.bottom: parent.bottom; anchors.left: parent.left; width: Theme.sideBarW; color: Theme.surface
        Rectangle { anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.right: parent.right; width: 1; color: Theme.line }
        Column { anchors.fill: parent; anchors.margins: 24; spacing: 8
            Text { text: "学习 / 五十音"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: Theme.label; font.letterSpacing: 1.8; bottomPadding: 14 }
            Repeater { model: ["总览", "单字详情", "弱项队列"]
                delegate: Button {
                    required property string modelData
                    required property int index
                    text: modelData; width: parent.width; height: 42; flat: true
                    leftPadding: 14
                    contentItem: Text { text: parent.text; color: index === 0 ? Theme.primary : Theme.textMuted; horizontalAlignment: Text.AlignLeft; verticalAlignment: Text.AlignVCenter; font.family: Theme.fontBody; font.pixelSize: 14; font.bold: index === 0 }
                    background: Rectangle { radius: Theme.radiusSm; color: index === 0 ? Qt.alpha(Theme.primary, 0.09) : "transparent"; Rectangle { visible: index === 0; width: 3; height: 20; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; color: Theme.accent; radius: 2 } }
                }
            }
            Item { height: 28; width: 1 }
            Text { text: "掌握进度"; color: Theme.textMuted; font.family: Theme.fontBody; font.pixelSize: 11; font.letterSpacing: 1.2 }
            Text { text: "12 / 50"; color: Theme.primary; font.family: Theme.fontDisplay; font.pixelSize: 30; font.bold: true; topPadding: 2 }
            Rectangle { width: parent.width; height: 4; radius: 2; color: Theme.line; Rectangle { width: parent.width * 0.24; height: parent.height; radius: 2; color: Theme.accent } }
            Text { text: "24% 已掌握"; color: Theme.textMuted; font.pixelSize: 11; topPadding: 3 }
        }
    }
    StackLayout { anchors.top: topBar.bottom; anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.leftMargin: Theme.sideBarW; anchors.right: parent.right; currentIndex: 0; KanaOverviewPage { } }
}
