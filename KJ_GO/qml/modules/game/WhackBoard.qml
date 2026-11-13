import QtQuick

Item {
    Repeater {
        model: whackMole.holes
        WhackHole {}
    }
}
