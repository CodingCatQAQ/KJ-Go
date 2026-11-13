#pragma once

#include <QString>

namespace game {

struct WhackTier {
    QString id;
    int prompts = 0;
    int concurrent = 1;
    int dwellMs = 1600;
    int wave = 4;

    static constexpr int kMinimumWords = 4;

    bool valid() const
    {
        return id == QLatin1String("calm") || id == QLatin1String("brisk") || id == QLatin1String("rush");
    }

    static WhackTier fromId(const QString &id)
    {
        if (id == QLatin1String("calm"))
            return {QStringLiteral("calm"), 8, 1, 1600, 4};
        if (id == QLatin1String("brisk"))
            return {QStringLiteral("brisk"), 12, 2, 1100, 5};
        if (id == QLatin1String("rush"))
            return {QStringLiteral("rush"), 16, 3, 750, 6};
        return {};
    }
};

}
