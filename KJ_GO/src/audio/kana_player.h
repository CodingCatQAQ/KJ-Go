#pragma once

#include <QObject>
#include <QUrl>

class QAudioOutput;
class QMediaPlayer;

class KanaPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool playing READ isPlaying NOTIFY playingChanged)
public:
    explicit KanaPlayer(QObject *parent = nullptr);
    Q_INVOKABLE void play(const QString &romaji);
    bool isPlaying() const;

signals:
    void playingChanged();

private:
    QString materialize(const QString &romaji);

    QMediaPlayer *m_player = nullptr;
    QAudioOutput *m_audio = nullptr;
    void startPending();

    QString m_dir;
    QUrl m_pendingUrl;
};
