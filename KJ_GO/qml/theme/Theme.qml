pragma Singleton
import QtQuick

QtObject {
    property bool dark: false
    readonly property QtObject palette: dark ? darkPalette : lightPalette
    readonly property QtObject lightPalette: LightPalette {}
    readonly property QtObject darkPalette: DarkPalette {}

    readonly property color bg: palette.bg
    readonly property color surface: palette.surface
    readonly property color text: palette.text
    readonly property color textMuted: palette.textMuted
    readonly property color line: palette.line
    readonly property color primary: palette.primary
    readonly property color accent: palette.accent
    readonly property color langKo: palette.langKo

    readonly property string fontDisplay: "Shippori Mincho"
    readonly property string fontBody: "Noto Sans SC"
    readonly property int kanaHero: 160
    readonly property int kanaPair: 56
    readonly property int kanaCell: 34
    readonly property int title: 36
    readonly property int body: 14
    readonly property int label: 11
    readonly property int unit: 8
    readonly property int topBarH: 64
    readonly property int sideBarW: 240
    readonly property int radiusSm: 4
    readonly property int radiusMd: 8
    readonly property int radiusXl: 16
    readonly property int durFast: 120
    readonly property int durFlip: 420
}
