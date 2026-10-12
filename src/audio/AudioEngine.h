#pragma once
#include <QList>
#include <QMediaDevices>
#include <QObject>
#include <QQueue>
#include <QStringList>
#include <QTimer>
#include <QUrl>

class QAudioOutput;
class QMediaPlayer;

class AudioEngine : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal masterVolume READ masterVolume WRITE setMasterVolume NOTIFY masterVolumeChanged)
    Q_PROPERTY(int playMode READ playMode WRITE setPlayMode NOTIFY playModeChanged)
    Q_PROPERTY(QStringList outputDevices READ outputDevices NOTIFY outputDevicesChanged)
    Q_PROPERTY(int outputDeviceIndex READ outputDeviceIndex WRITE setOutputDeviceIndex NOTIFY outputDeviceIndexChanged)
    Q_PROPERTY(QStringList playingIds READ playingIds NOTIFY playingIdsChanged)
    Q_PROPERTY(int queueLength READ queueLength NOTIFY queueChanged)
    Q_PROPERTY(qint64 positionMs READ positionMs NOTIFY positionChanged)
    Q_PROPERTY(qint64 durationMs READ durationMs NOTIFY durationChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY positionChanged)
    Q_PROPERTY(bool paused READ paused NOTIFY playbackStateChanged)
    Q_PROPERTY(bool hasDuration READ hasDuration NOTIFY durationChanged)

public:
    enum PlayMode { StopPrevious = 0, Overlay = 1, Queue = 2 };
    Q_ENUM(PlayMode)

    explicit AudioEngine(QObject *parent = nullptr);
    ~AudioEngine() override;

    qreal masterVolume() const { return m_master; }
    int playMode() const { return m_mode; }
    QStringList outputDevices() const;
    int outputDeviceIndex() const { return m_deviceIndex; }
    QStringList playingIds() const;
    int queueLength() const { return m_queue.size(); }
    qint64 positionMs() const { return m_posMs; }
    qint64 durationMs() const { return m_durMs; }
    bool hasDuration() const { return m_durMs > 0; }
    qreal progress() const;
    bool paused() const { return m_paused; }

    void setMasterVolume(qreal v);
    void setPlayMode(int m);
    void setOutputDeviceIndex(int i);

    void play(const QString &id, const QUrl &source, qreal gain, bool force = false);

    Q_INVOKABLE void stop(const QString &id);
    Q_INVOKABLE void stopAll();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void resume();
    Q_INVOKABLE void togglePause();
    Q_INVOKABLE bool isPlaying(const QString &id) const;
    Q_INVOKABLE bool isActive(const QString &id) const;
    Q_INVOKABLE qreal progressOf(const QString &id) const;
    Q_INVOKABLE void seek(qreal fraction);
    Q_INVOKABLE void seekMs(qint64 ms);

signals:
    void masterVolumeChanged();
    void playModeChanged();
    void outputDevicesChanged();
    void outputDeviceIndexChanged();
    void playingIdsChanged();
    void queueChanged();
    void positionChanged();
    void durationChanged();
    void playbackStateChanged();
    void trackEnded(const QString &id);
    void errorOccurred(const QString &message);

private:
    struct Voice {
        QMediaPlayer *player = nullptr;
        QAudioOutput *out = nullptr;
        QString id;
        qreal gain = 1.0;
        bool busy = false;
        bool everPlayed = false;
    };
    struct QueuedItem {
        QString id;
        QUrl source;
        qreal gain;
    };

    Voice *primaryVoice() const;
    Voice *acquire();
    void startVoice(const QString &id, const QUrl &source, qreal gain);
    void endCurrentTrack(Voice *v);
    void hardStop(Voice *v);
    void playNextInQueue();
    bool anyBusy() const;
    void applyVolume(Voice *v);
    QAudioDevice deviceFor(int index) const;
    void tick();
    void setPos(qint64 ms);
    void setDur(qint64 ms);

    static constexpr int kMaxVoices = 8;

    QList<Voice *> m_voices;
    QQueue<QueuedItem> m_queue;
    QMediaDevices m_devices;
    QTimer m_tick;
    qreal m_master = 0.8;
    int m_mode = StopPrevious;
    int m_deviceIndex = 0;
    qint64 m_posMs = 0;
    qint64 m_durMs = 0;
    bool m_paused = false;
    bool m_seeking = false;
    bool m_ignoreStopped = false;
    int m_stallTicks = 0;
    qint64 m_lastTickPos = -1;
};
