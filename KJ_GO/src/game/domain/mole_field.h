#pragma once

#include <QString>
#include <array>

namespace game {

enum class WhackOutcome { Empty, Correct, Wrong };

class MoleField {
public:
    static constexpr int kHoleCount = 6;

    void reset();
    bool pop(int hole, const QString &wordId, const QString &label, bool target);
    WhackOutcome whack(int hole);
    bool sink(int hole);

    bool occupied(int hole) const;
    QString label(int hole) const;
    int occupiedCount() const;

private:
    struct Slot {
        QString wordId;
        QString label;
        bool target = false;
        bool occupied = false;
    };

    std::array<Slot, kHoleCount> m_slots{};
};

}
