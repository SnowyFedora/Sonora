#pragma once
#include <QJsonValue>
#include <QObject>
#include <QProcess>
#include <QUrl>
#include <QVariantList>
#include <functional>

class YtmClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(QVariantList tracks READ tracks NOTIFY tracksChanged)
    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString currentArtist READ currentArtist NOTIFY nowPlayingChanged)
    Q_PROPERTY(QString currentId READ currentId NOTIFY nowPlayingChanged)
    Q_PROPERTY(bool playing READ playing NOTIFY nowPlayingChanged)

public:
    explicit YtmClient(QObject *parent = nullptr);

    bool available() const { return m_available; }
    bool busy() const { return m_busy; }
    QString status() const { return m_status; }
    QVariantList tracks() const { return m_tracks; }
    QString currentTitle() const { return m_curTitle; }
    QString currentArtist() const { return m_curArtist; }
    QString currentId() const { return m_curId; }
    bool playing() const { return m_playing; }

    Q_INVOKABLE void checkDeps();
    Q_INVOKABLE void search(const QString &query);
    Q_INVOKABLE void loadHome();
    Q_INVOKABLE void playTrack(const QString &videoId, const QString &title, const QString &artist);
    Q_INVOKABLE void stop();

    void setPlayCallback(std::function<void(const QString &id, const QUrl &url, qreal gain)> cb)
    {
        m_playCb = std::move(cb);
    }
    void setStopCallback(std::function<void()> cb) { m_stopCb = std::move(cb); }
    void setPlaying(bool v);

signals:
    void availableChanged();
    void busyChanged();
    void statusChanged();
    void tracksChanged();
    void nowPlayingChanged();
    void errorOccurred(const QString &message);

private:
    void run(const QStringList &args, const std::function<void(const QJsonValue &)> &onOk);
    void setBusy(bool v);
    void setStatus(const QString &s);
    QString scriptPath() const;
    QString pythonBin() const;

    QProcess *m_proc = nullptr;
    bool m_available = false;
    bool m_busy = false;
    QString m_status;
    QVariantList m_tracks;
    QString m_curTitle;
    QString m_curArtist;
    QString m_curId;
    bool m_playing = false;
    std::function<void(const QString &, const QUrl &, qreal)> m_playCb;
    std::function<void()> m_stopCb;
};
