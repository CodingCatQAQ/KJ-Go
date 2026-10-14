import QtQuick
import QtQuick.Controls
import QtQuick.Window
import "theme"
import "shell"

ApplicationWindow {
    id: window
    width: 1280
    height: 800
    minimumWidth: 1024
    minimumHeight: 640
    visibility: Window.Maximized
    title: "若澄的语言学习工具"
    color: Theme.bg
    AppShell { anchors.fill: parent }
}
