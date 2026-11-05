#include "audio/kana_player.h"
#include "game/infrastructure/study_vocab_catalog.h"
#include "game/presentation/memory_match_game.h"
#include "study/study_store.h"

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QGuiApplication::setOrganizationName(QStringLiteral("KJ"));
    QGuiApplication::setApplicationName(QStringLiteral("KJ_GO"));

    QQmlApplicationEngine engine;
    KanaPlayer kanaPlayer;
    StudyStore studyStore;
    game::StudyVocabCatalog vocabCatalog(studyStore);
    game::MemoryMatchGame memoryMatch(vocabCatalog);
    QObject::connect(&studyStore, &StudyStore::changed, &memoryMatch, &game::MemoryMatchGame::reloadPool);
    engine.rootContext()->setContextProperty(QStringLiteral("kanaPlayer"), &kanaPlayer);
    engine.rootContext()->setContextProperty(QStringLiteral("studyStore"), &studyStore);
    engine.rootContext()->setContextProperty(QStringLiteral("memoryMatch"), &memoryMatch);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("KJ_GO", "Main");

    return QGuiApplication::exec();
}
