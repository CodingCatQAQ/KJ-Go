#pragma once

#include "game/application/mole_dealer.h"
#include "game/application/vocab_catalog.h"
#include "game/domain/mole_field.h"
#include "game/domain/whack_tier.h"
#include "game/presentation/mole_hole_model.h"
#include "study/study_store.h"

#include <QElapsedTimer>
#include <QObject>
#include <QRandomGenerator>
#include <QTimer>
#include <QVariantList>
#include <array>

namespace game {

class WhackMoleGame : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString setId READ setId WRITE setSetId NOTIFY setIdChanged)
    Q_PROPERTY(QString phase READ phase NOTIFY changed)
    Q_PROPERTY(QString promptText READ promptText NOTIFY changed)
    Q_PROPERTY(int promptNumber READ promptNumber NOTIFY changed)
    Q_PROPERTY(int promptTotal READ promptTotal NOTIFY changed)
    Q_PROPERTY(int hits READ hits NOTIFY changed)
    Q_PROPERTY(int wrongTaps READ wrongTaps NOTIFY changed)
    Q_PROPERTY(int escapes READ escapes NOTIFY changed)
    Q_PROPERTY(int seconds READ seconds NOTIFY changed)
    Q_PROPERTY(int usableCount READ usableCount NOTIFY changed)
    Q_PROPERTY(QString moleFace READ moleFace NOTIFY changed)
    Q_PROPERTY(bool perfect READ perfect NOTIFY changed)
    Q_PROPERTY(MoleHoleModel *holes READ holes CONSTANT)
    Q_PROPERTY(QVariantList recap READ recap NOTIFY changed)
public:
    explicit WhackMoleGame(VocabCatalog &catalog, StudyStore &store, QObject *parent = nullptr);

    QString setId() const;
    void setSetId(const QString &setId);
    QString phase() const;
    QString promptText() const;
    int promptNumber() const;
    int promptTotal() const;
    int hits() const;
    int wrongTaps() const;
    int escapes() const;
    int seconds() const;
    int usableCount() const;
    QString moleFace() const;
    bool perfect() const;
    MoleHoleModel *holes() const;
    QVariantList recap() const;

    Q_INVOKABLE bool canStart(const QString &tierId) const;
    Q_INVOKABLE int shortfall(const QString &tierId) const;
    Q_INVOKABLE bool start(const QString &tierId, const QString &direction);
    Q_INVOKABLE void whack(int hole);
    Q_INVOKABLE void again();
    Q_INVOKABLE void replay();
    Q_INVOKABLE void endRound();
    Q_INVOKABLE void setRunning(bool running);

public slots:
    void reloadPool();

signals:
    void changed();
    void setIdChanged();

private slots:
    void tick();

private:
    void resetRound();
    void beginRound(const WhackTier &tier, PromptFace face, const WhackRound &round);
    void openPrompt();
    void finishPrompt(bool correct);
    void clearField();
    int freeHole();
    qint64 now() const;
    const MolePrompt *currentPrompt() const;

    VocabCatalog &m_catalog;
    StudyStore &m_store;
    MoleHoleModel *m_holes;
    QVector<VocabWord> m_usableWords;
    QVector<VocabWord> m_pool;
    QVector<MolePrompt> m_prompts;
    QVariantList m_recap;
    WhackTier m_tier;
    PromptFace m_face = PromptFace::Gloss;
    MoleField m_field;
    QString m_setId;
    QString m_phase = QStringLiteral("setup");
    int m_promptIndex = 0;
    int m_waveIndex = 0;
    int m_hits = 0;
    int m_wrongTaps = 0;
    int m_escapes = 0;
    int m_seconds = 0;
    bool m_between = false;
    bool m_resolved = false;
    bool m_running = true;
    bool m_paused = false;
    qint64 m_held = 0;
    qint64 m_pausedAt = 0;
    qint64 m_nextSpawnAt = 0;
    qint64 m_resumeAt = 0;
    std::array<qint64, MoleField::kHoleCount> m_hideAt{};
    QTimer m_timer;
    QElapsedTimer m_clock;
    QRandomGenerator m_random;
};

}
