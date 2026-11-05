import QtQuick

Item {
    id: board

    Repeater {
        model: memoryMatch.cards
        MemoryCard {}
    }
}
