#include "audio/kana_player.h"
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
    engine.rootContext()->setContextProperty(QStringLiteral("kanaPlayer"), &kanaPlayer);
    engine.rootContext()->setContextProperty(QStringLiteral("studyStore"), &studyStore);
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("KJ_GO", "Main");

    return QGuiApplication::exec();
}
