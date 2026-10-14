#include "kana_player.h"

#include <QAudioOutput>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QMediaPlayer>
#include <QStandardPaths>
#include <QTimer>
#include <QUrl>
#include <QDebug>

KanaPlayer::KanaPlayer(QObject *parent)
    : QObject(parent)
{
    m_audio = new QAudioOutput(this);
    m_audio->setVolume(1.0);
    m_player = new QMediaPlayer(this);
    m_player->setAudioOutput(m_audio);
    QObject::connect(m_player, &QMediaPlayer::errorOccurred, m_player, [](QMediaPlayer::Error, const QString &message) {
        qWarning() << "kana audio:" << message;
    });
    QObject::connect(m_player, &QMediaPlayer::playbackStateChanged, this, [this](QMediaPlayer::PlaybackState) {
        emit playingChanged();
    });
    QObject::connect(m_player, &QMediaPlayer::mediaStatusChanged, this, [this](QMediaPlayer::MediaStatus status) {
        if (status == QMediaPlayer::EndOfMedia) {
            if (m_pendingUrl.isEmpty())
                m_player->stop();
            return;
        }
        if (status == QMediaPlayer::LoadedMedia || status == QMediaPlayer::BufferedMedia)
            QTimer::singleShot(0, this, [this] { startPending(); });
    });
}

void KanaPlayer::startPending()
{
    if (m_pendingUrl.isEmpty() || m_player->source() != m_pendingUrl)
        return;
    const auto status = m_player->mediaStatus();
    if (status != QMediaPlayer::LoadedMedia && status != QMediaPlayer::BufferedMedia)
        return;
    m_pendingUrl.clear();
    m_player->setPosition(0);
    m_player->play();
}

bool KanaPlayer::isPlaying() const
{
    return m_player && m_player->playbackState() == QMediaPlayer::PlayingState;
}

QString KanaPlayer::materialize(const QString &romaji)
{
    if (romaji.isEmpty() || romaji.contains(QLatin1Char('/')) || romaji.contains(QLatin1Char('\\'))
        || romaji.contains(QLatin1String("..")))
        return {};

    if (m_dir.isEmpty()) {
        m_dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/kana");
        QDir().mkpath(m_dir);
    }

    const QString dest = m_dir + QLatin1Char('/') + romaji + QStringLiteral(".mp3");
    if (QFileInfo::exists(dest) && QFileInfo(dest).size() > 500)
        return dest;

    QFile in(QStringLiteral(":/qt/qml/KJ_GO/audio/seion/%1.mp3").arg(romaji));
    if (!in.open(QIODevice::ReadOnly))
        return {};
    QFile out(dest);
    if (!out.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return {};
    const QByteArray bytes = in.readAll();
    if (out.write(bytes) != bytes.size())
        return {};
    out.close();
    return dest;
}

void KanaPlayer::play(const QString &romaji)
{
    const QString path = materialize(romaji);
    if (path.isEmpty())
        return;

    const QUrl url = QUrl::fromLocalFile(path);
    const auto status = m_player->mediaStatus();
    const bool sameAndReady = m_player->source() == url
        && (status == QMediaPlayer::LoadedMedia
            || status == QMediaPlayer::BufferedMedia
            || status == QMediaPlayer::EndOfMedia);

    m_player->stop();
    if (sameAndReady) {
        m_pendingUrl.clear();
        m_player->setPosition(0);
        m_player->play();
        return;
    }

    m_pendingUrl = url;
    m_player->setSource(url);
    QTimer::singleShot(0, this, [this] { startPending(); });
}
