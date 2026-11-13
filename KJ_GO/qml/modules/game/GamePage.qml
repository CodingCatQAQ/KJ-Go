import QtQuick
import "../../shell"

Item {
    id: root
    property string view: "memory"
    property string setId: "ja-vocab"
    property bool running: true
    signal openVocab()

    MemoryMatchPage {
        anchors.fill: parent
        visible: root.view === "memory"
        setId: root.setId
        onOpenVocab: root.openVocab()
    }

    WhackMolePage {
        anchors.fill: parent
        visible: root.view === "whack"
        setId: root.setId
        running: root.running && root.view === "whack"
        onOpenVocab: root.openVocab()
    }

    ModulePlaceholder {
        anchors.fill: parent
        visible: root.view !== "memory" && root.view !== "whack"
        title: "游戏"
        kana: "遊"
        note: "这个玩法还在规划里。"
    }
}
