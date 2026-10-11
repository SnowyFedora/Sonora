#pragma once
#include "audio/AudioEngine.h"
#include "hotkeys/HotkeyManager.h"
#include "library/SoundLibrary.h"
#include "theme/ThemeEngine.h"

#include <QObject>
#include <QUrl>

class AppController : public QObject {
    Q_OBJECT
    Q_PROPERTY(QObject *theme READ theme CONSTANT)
    Q_PROPERTY(QObject *library READ library CONSTANT)
    Q_PROPERTY(QObject *engine READ engine CONSTANT)
    Q_PROPERTY(QObject *hotkeys READ hotkeys CONSTANT)
    Q_PROPERTY(bool alwaysOnTop READ alwaysOnTop WRITE setAlwaysOnTop NOTIFY alwaysOnTopChanged)
    Q_PROPERTY(QString stopAllHotkey READ stopAllHotkey WRITE setStopAllHotkey NOTIFY stopAllHotkeyChanged)
    // Now playing (локальная библиотека)
    Q_PROPERTY(QString nowPlayingId READ nowPlayingId NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString nowPlayingTitle READ nowPlayingTitle NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString nowPlayingArtist READ nowPlayingArtist NOTIFY nowPlayingChanged)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY nowPlayingChanged)

public:
    explicit AppController(QObject *parent = nullptr);

    QObject *theme() { return &m_theme; }
    QObject *library() { return &m_library; }
    QObject *engine() { return &m_engine; }
    QObject *hotkeys() { return &m_hotkeys; }

    bool alwaysOnTop() const { return m_alwaysOnTop; }
    void setAlwaysOnTop(bool v);
    QString stopAllHotkey() const { return m_stopAllHotkey; }
    void setStopAllHotkey(const QString &seq);

    QString nowPlayingId() const { return m_nowId; }
    QString nowPlayingTitle() const { return m_nowTitle; }
    QString nowPlayingArtist() const { return m_nowArtist; }
    bool isPlaying() const;

    Q_INVOKABLE void play(const QString &soundId);
    Q_INVOKABLE void playNext();
    Q_INVOKABLE void playPrevious();
    Q_INVOKABLE void stopPlayback();
    Q_INVOKABLE void toggleFavorite(const QString &soundId);
    Q_INVOKABLE int addFolder(const QUrl &folderUrl);
    Q_INVOKABLE int addUrls(const QList<QUrl> &urls);
    Q_INVOKABLE void pickFolder();
    Q_INVOKABLE void pickFiles();
    Q_INVOKABLE void pickImage();
    Q_INVOKABLE QString assignHotkey(const QString &soundId, const QString &sequence);
    // Открыть файлы/папки из аргументов ОС (ассоциация «открыть с помощью»)
    Q_INVOKABLE void openPaths(const QStringList &paths);

signals:
    void alwaysOnTopChanged();
    void stopAllHotkeyChanged();
    void nowPlayingChanged();
    void toast(const QString &message);

private:
    void syncHotkeys();
    void setNowPlaying(const QString &id);

    ThemeEngine m_theme;
    SoundLibrary m_library;
    AudioEngine m_engine;
    HotkeyManager m_hotkeys;
    bool m_alwaysOnTop = false;
    QString m_stopAllHotkey;
    QString m_nowId;
    QString m_nowTitle;
    QString m_nowArtist;
    QStringList m_queue; // ids for next/prev in session
    int m_queueIndex = -1;
};
