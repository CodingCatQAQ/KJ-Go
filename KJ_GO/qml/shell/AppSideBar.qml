import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root
    property int module: 0
    property string language: "ja"
    property string studyView: "overview"
    property string kanaChart: "seion"
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
    function chartTotal(setId) {
        var rev = studyStore.revision
        var counts = studyStore.counts(setId)
        return counts && counts.total ? counts.total : 0
    }
    readonly property int hangulTotal: { var rev = studyStore.revision; return chartTotal("ko-syllable") }
    readonly property int seionTotal: { var rev = studyStore.revision; return chartTotal("ja-seion") }
    readonly property int dakuonTotal: { var rev = studyStore.revision; return chartTotal("ja-dakuon") }
    readonly property int handakuonTotal: { var rev = studyStore.revision; return chartTotal("ja-handakuon") }
    readonly property int youonTotal: { var rev = studyStore.revision; return chartTotal("ja-youon") }
    readonly property string jaChartLabel: {
        if (kanaChart === "dakuon")
            return "浊音"
        if (kanaChart === "handakuon")
            return "半浊音"
        if (kanaChart === "youon")
            return "拗音"
        return "清音"
    }
    readonly property int vocabTotal: {
        var rev = studyStore.revision
        var counts = studyStore.counts(root.korean ? "ko-vocab" : "ja-vocab")
        return counts && counts.total ? counts.total : 0
    }
    readonly property string koFront: (frontScript === "gloss" || frontScript === "mix" || frontScript === "word") ? frontScript : "word"
    readonly property string jaFront: (frontScript === "kata" || frontScript === "mix" || frontScript === "hira") ? frontScript : "hira"
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
            NavItem {
                visible: root.korean
                Layout.fillWidth: true
                label: "谚文"
                meta: "" + root.hangulTotal
                active: root.studyView === "overview"
                onPicked: root.openStudy("overview")
            }
            NavItem {
                visible: !root.korean
                Layout.fillWidth: true
                label: "清音"
                meta: "" + root.seionTotal
                active: root.studyView === "overview" && root.kanaChart === "seion"
                onPicked: root.openStudy("seion")
            }
            NavItem {
                visible: !root.korean
                Layout.fillWidth: true
                label: "浊音"
                meta: "" + root.dakuonTotal
                active: root.studyView === "overview" && root.kanaChart === "dakuon"
                onPicked: root.openStudy("dakuon")
            }
            NavItem {
                visible: !root.korean
                Layout.fillWidth: true
                label: "半浊音"
                meta: "" + root.handakuonTotal
                active: root.studyView === "overview" && root.kanaChart === "handakuon"
                onPicked: root.openStudy("handakuon")
            }
            NavItem {
                visible: !root.korean
                Layout.fillWidth: true
                label: "拗音"
                meta: "" + root.youonTotal
                active: root.studyView === "overview" && root.kanaChart === "youon"
                onPicked: root.openStudy("youon")
            }
            NavItem {
                Layout.fillWidth: true
                label: "词汇"
                meta: "" + root.vocabTotal
                active: root.studyView === "vocab"
                onPicked: root.openStudy("vocab")
            }

            Item { height: 28; width: 1 }
            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                SectionLabel { text: "后续模块" }
                NavItem { Layout.fillWidth: true; label: "语法"; soon: true }
            }
        }

        ColumnLayout {
            visible: root.module === 1
            spacing: 2
            Layout.fillWidth: true
            SectionLabel { text: "复习队列" }
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
                label: root.korean ? "全部词汇" : ("全部" + root.jaChartLabel)
                meta: "" + (root.counts.total || 0)
                active: root.queueMode === "all"
                onPicked: root.pickQueue("all")
            }
            Item { height: 28; width: 1 }
            ColumnLayout {
                visible: !root.korean
                spacing: 2
                Layout.fillWidth: true
                SectionLabel { text: "正面显示" }
                NavItem {
                    Layout.fillWidth: true
                    label: "平假名"
                    active: root.jaFront === "hira"
                    onPicked: root.pickFront("hira")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "片假名"
                    active: root.jaFront === "kata"
                    onPicked: root.pickFront("kata")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "随机混合"
                    active: root.jaFront === "mix"
                    onPicked: root.pickFront("mix")
                }
            }
            ColumnLayout {
                visible: root.korean
                spacing: 2
                Layout.fillWidth: true
                SectionLabel { text: "正面显示" }
                NavItem {
                    Layout.fillWidth: true
                    label: "韩语单词"
                    active: root.koFront === "word"
                    onPicked: root.pickFront("word")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "中文释义"
                    active: root.koFront === "gloss"
                    onPicked: root.pickFront("gloss")
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "随机混合"
                    active: root.koFront === "mix"
                    onPicked: root.pickFront("mix")
                }
            }
        }

        ColumnLayout {
            visible: root.module === 2 || root.module === 3
            spacing: 2
            Layout.fillWidth: true
            SectionLabel { text: root.module === 2 ? "游戏" : "统计" }
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
