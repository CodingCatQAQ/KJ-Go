import QtQuick
import QtQuick.Controls
import "theme"
import "shell"

ApplicationWindow {
    id: window
    visible: true
    width: 1280
    height: 800
    minimumWidth: 1024
    minimumHeight: 640
    title: "KANA · 日语记忆工具"
    color: Theme.bg
    AppShell { anchors.fill: parent }
}
