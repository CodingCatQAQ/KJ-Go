#pragma once

namespace game {

struct BoardTier {
    int side = 0;

    int pairs() const { return side * side / 2; }
    int cards() const { return side * side; }
    bool valid() const { return side == 4 || side == 6 || side == 8; }

    static BoardTier fromSide(int side)
    {
        if (side == 4 || side == 6 || side == 8)
            return BoardTier{side};
        return {};
    }
};

}
