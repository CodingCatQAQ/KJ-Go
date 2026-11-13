#include "game/domain/mole_field.h"

namespace game {

void MoleField::reset()
{
    for (Slot &slot : m_slots)
        slot = {};
}

bool MoleField::pop(int hole, const QString &wordId, const QString &label, bool target)
{
    if (hole < 0 || hole >= kHoleCount)
        return false;
    if (wordId.isEmpty() || label.isEmpty() || m_slots[hole].occupied)
        return false;
    if (target) {
        for (const Slot &slot : m_slots) {
            if (slot.occupied && slot.target)
                return false;
        }
    }

    Slot &slot = m_slots[hole];
    slot.wordId = wordId;
    slot.label = label;
    slot.target = target;
    slot.occupied = true;
    return true;
}

WhackOutcome MoleField::whack(int hole)
{
    if (hole < 0 || hole >= kHoleCount || !m_slots[hole].occupied)
        return WhackOutcome::Empty;
    const bool target = m_slots[hole].target;
    m_slots[hole] = {};
    return target ? WhackOutcome::Correct : WhackOutcome::Wrong;
}

bool MoleField::sink(int hole)
{
    if (hole < 0 || hole >= kHoleCount || !m_slots[hole].occupied)
        return false;
    const bool target = m_slots[hole].target;
    m_slots[hole] = {};
    return target;
}

bool MoleField::occupied(int hole) const
{
    return hole >= 0 && hole < kHoleCount && m_slots[hole].occupied;
}

QString MoleField::label(int hole) const
{
    if (!occupied(hole))
        return {};
    return m_slots[hole].label;
}

int MoleField::occupiedCount() const
{
    int count = 0;
    for (const Slot &slot : m_slots) {
        if (slot.occupied)
            ++count;
    }
    return count;
}

}
