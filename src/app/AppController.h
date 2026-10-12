#pragma once
#include "audio/AudioEngine.h"
#include "hotkeys/HotkeyManager.h"
#include "library/SoundLibrary.h"
#include "theme/ThemeEngine.h"

#include <QObject>
#include <QTimer>
#include <QUrl>

class AppController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QObject *theme READ theme CONSTANT)
    Q_PROPERTY(QObject *library READ library CONSTANT)
    Q_PROPERTY(QObject *engine READ engine CONSTANT)
    Q_PROPERTY(QObject *hotkeys READ hotkeys CONSTANT)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY alwaysOnTopChanged)
    Q_PROPERTY(QString stopAllHotkey READ stopAllHotkey WRITE setStopAllHotkey NOTIFY stopAllHotkeyChanged)
    Q_PROPERTY(QString nowPlayingId READ nowPlayingId NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString nowPlayingTitle READ nowPlayingTitle NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString nowPlayingArtist READ nowPlayingArtist NOTIFY nowPlayingChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY nowPlayingChanged)
    Q_PROPERTY(bool isPaused READ isPaused NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString version READ version CONSTANT)

public:
    explicit AppController(QObject *parent = nullptr);

    QObject *theme() { return &m_theme; }
    QObject *library() { return &m_library; }
    QObject *engine() { return &m_engine; }
    QObject *hotkeys() { return &m_hotkeys; }
    QString version() const { return QStringLiteral("0.2.1"); }

    bool alwaysOnTop() const { return m_alwaysOnTop; }
    void setAlwaysOnTop(bool v);
    QString stopAllHotkey() const { return m_stopAllHotkey; }
    void setStopAllHotkey(const QString &seq);

    QString nowPlayingId() const { return m_nowId; }
    QString nowPlayingTitle() const { return m_nowTitle; }
    QString nowPlayingArtist() const { return m_nowArtist; }
    bool isPlaying() const;
    bool isPaused() const;

    Q_INVOKABLE void play(const QString &soundId);
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrevious();
    Q_INVOKABLE void stopPlayback();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE void toggleFavorite(const QString &soundId);
    Q_INVOKABLE void removeSound(const QString &soundId);
    Q_INVOKABLE int addFolder(const QUrl &folderUrl);
    Q_INVOKABLE int addUrls(const QList<QUrl> &urls);
    Q_INVOKABLE void pickFolder();
    Q_INVOKABLE void pickFiles();
    Q_INVOKABLE void pickImage();
    Q_INVOKABLE QString assignHotkey(const QString &soundId, const QString &sequence);
    Q_INVOKABLE void openPaths(const QStringList &paths);

signals:
    void alwaysOnTopChanged();
    void stopAllHotkeyChanged();
    void nowPlayingChanged();
    void toast(const QString &message);

private:
    void syncHotkeys();
    void setNowPlaying(const QString &id);
    void rebuildQueueFromLibrary();
    void playForced(const QString &soundId);
    void watchTick();

    ThemeEngine m_theme;
    SoundLibrary m_library;
    AudioEngine m_engine;
    HotkeyManager m_hotkeys;
    QTimer m_watch;
    bool m_alwaysOnTop = false;
    QString m_stopAllHotkey;
    QString m_nowId;
    QString m_nowTitle;
    QString m_nowArtist;
    QStringList m_queue;
    int m_queueIndex = -1;
    bool m_hadPlayback = false;
    bool m_advancing = false;
    bool m_userStopped = false;
};
