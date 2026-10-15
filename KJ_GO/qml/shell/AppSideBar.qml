import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root
    property int module: 0
    property string language: "ja"
    property string studyView: "overview"
    property string filter: "all"
    property var counts: ({ total: 0, mastered: 0, learning: 0, fresh: 0 })
    property int weakCount: 0
    property int reviewCount: 0
    property string queueMode: "today"
    property string frontScript: "hira"
    signal openStudy(string view)
    signal pickFilter(string id)
    signal pickQueue(string id)
    signal pickFront(string id)

    readonly property bool korean: language === "ko"
    readonly property int masteredPct: counts.total > 0 ? Math.round(counts.mastered / counts.total * 100) : 0

    component SectionLabel: Text {
        color: Theme.textMuted
        font.family: Theme.fontBody
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 2
        leftPadding: 12
        bottomPadding: 8
    }

    component NavItem: Rectangle {
        id: nav
        property string label: ""
        property string meta: ""
        property bool metaSerif: false
        property bool active: false
        property bool soon: false
        property bool coralDot: false
        signal picked()
        implicitHeight: 36
        radius: Theme.radiusMd
        color: active ? Theme.muted : (navHover.hovered && !soon ? Qt.rgba(Theme.muted.r, Theme.muted.g, Theme.muted.b, 0.6) : "transparent")

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Rectangle {
                visible: nav.active
                width: 2
                height: 14
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: nav.label
                color: nav.soon ? Qt.rgba(Theme.textMuted.r, Theme.textMuted.g, Theme.textMuted.b, 0.7) : Theme.text
                font.family: Theme.fontBody
                font.pixelSize: 14
                font.bold: nav.active
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Text {
            visible: nav.meta !== "" && !nav.soon && !nav.coralDot
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: nav.meta
            color: Theme.textMuted
            font.family: nav.metaSerif ? Theme.fontDisplay : Theme.fontBody
            font.pixelSize: nav.metaSerif ? 16 : 12
        }
        Rectangle {
            visible: nav.soon
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: soonText.implicitWidth + 12
            implicitHeight: 16
            radius: 2
            color: "transparent"
            border.width: 1
            border.color: Theme.line
            Text {
                id: soonText
                anchors.centerIn: parent
                text: "规划中"
                color: Theme.textMuted
                font.family: Theme.fontBody
                font.pixelSize: 10
                font.letterSpacing: 1
            }
        }
        Rectangle {
            visible: nav.coralDot
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 8
            height: 8
            radius: 4
            color: Theme.langKo
        }
        HoverHandler { id: navHover; enabled: !nav.soon }
        TapHandler {
            enabled: !nav.soon
            onTapped: nav.picked()
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: Theme.border
    }

    Item {
        id: logoSlot
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.topBarH

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: "若澄QAQ"
            color: Theme.text
            font.family: Theme.fontDisplay
            font.pixelSize: 22
            font.bold: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.border
        }
    }

    ColumnLayout {
        anchors.top: logoSlot.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 24
        anchors.bottomMargin: 20
        spacing: 0

        ColumnLayout {
            visible: root.module === 0
            spacing: 2
            Layout.fillWidth: true
            SectionLabel { text: root.korean ? "音节 · SYLLABLE" : "五十音 · GOJŪON" }
            NavItem {
                Layout.fillWidth: true
                label: root.korean ? "音节总览" : "清音总览"
                meta: "" + (root.counts.total || 0)
                active: root.studyView === "overview"
                onPicked: root.openStudy("overview")
            }
            NavItem { visible: !root.korean; Layout.fillWidth: true; label: "浊音 · 半浊音"; soon: true }
            NavItem { visible: !root.korean; Layout.fillWidth: true; label: "拗音"; soon: true }

            Item { height: 28; width: 1 }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                SectionLabel { text: "后续模块 · NEXT" }
                NavItem { Layout.fillWidth: true; label: "词汇"; soon: true }
                NavItem { Layout.fillWidth: true; label: "语法"; soon: true }
            }
        }

        ColumnLayout {
            visible: root.module === 1
            spacing: 2
            Layout.fillWidth: true
            SectionLabel { text: "复习队列 · QUEUE" }
            NavItem {
                Layout.fillWidth: true
                label: "今日复习"
                meta: "" + root.reviewCount
                active: root.queueMode === "today"
                onPicked: root.pickQueue("today")
            }
            NavItem {
                Layout.fillWidth: true
                label: "模糊"
                meta: "" + root.weakCount
                active: root.queueMode === "fuzzy"
                onPicked: root.pickQueue("fuzzy")
            }
            NavItem {
                Layout.fillWidth: true
                label: root.korean ? "全部音节" : "全部五十音"
                meta: "" + (root.counts.total || 0)
                active: root.queueMode === "all"
                onPicked: root.pickQueue("all")
            }
            Item { visible: !root.korean; height: 28; width: 1 }
            ColumnLayout {
                visible: !root.korean
                spacing: 2
                Layout.fillWidth: true
                SectionLabel { text: "正面显示 · FRONT" }
                NavItem {
                    Layout.fillWidth: true
                    label: "平假名"
                    active: root.frontScript === "hira"
                    onPicked: root.pickFront("hira")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "片假名"
                    active: root.frontScript === "kata"
                    onPicked: root.pickFront("kata")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "随机混合"
                    active: root.frontScript === "mix"
                    onPicked: root.pickFront("mix")
                }
            }
        }

        ColumnLayout {
            visible: root.module === 2 || root.module === 3
            spacing: 2
            Layout.fillWidth: true
            SectionLabel { text: root.module === 2 ? "游戏 · GAMES" : "统计 · STATS" }
            NavItem { Layout.fillWidth: true; label: root.module === 2 ? "假名打地鼠" : "总览"; soon: true }
            NavItem { Layout.fillWidth: true; label: root.module === 2 ? "听音辨字" : "记忆曲线"; soon: true }
            NavItem { Layout.fillWidth: true; label: root.module === 2 ? "限时连线" : "弱项热力图"; soon: true }
        }

        Item { Layout.fillHeight: true }

        Column {
            Layout.fillWidth: true
            spacing: 8
            Row {
                width: parent.width
                Text {
                    text: "已掌握"
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 2
                }
                Item { width: parent.width - 90; height: 1 }
                Text {
                    text: root.counts.mastered
                    color: Theme.text
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                    font.bold: true
                }
                Text {
                    text: " / " + root.counts.total
                    color: Theme.textMuted
                    font.family: Theme.fontBody
                    font.pixelSize: 14
                }
            }
            Rectangle {
                width: parent.width
                height: 2
                color: Theme.border
                Rectangle { width: parent.width * root.masteredPct / 100; height: parent.height; color: Theme.accent }
            }
        }
    }
}
