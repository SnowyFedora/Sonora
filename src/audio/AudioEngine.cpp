#include "AudioEngine.h"

#include <QAudioDevice>
#include <QAudioOutput>
#include <QMediaPlayer>
#include <QSettings>
#include <algorithm>

AudioEngine::AudioEngine(QObject *parent)
    : QObject(parent)
{
    QSettings st;
    m_master = st.value("audio/master", 0.8).toDouble();
    m_mode = st.value("audio/mode", int(StopPrevious)).toInt();
    m_deviceIndex = 0;

    connect(&m_devices, &QMediaDevices::audioOutputsChanged, this, [this] {
        if (m_deviceIndex > m_devices.audioOutputs().size())
            setOutputDeviceIndex(0);
        emit outputDevicesChanged();
    });
}

AudioEngine::~AudioEngine()
{
    qDeleteAll(m_voices);
}

QStringList AudioEngine::outputDevices() const
{
    QStringList l{tr("Системное по умолчанию")};
    for (const QAudioDevice &d : QMediaDevices::audioOutputs())
        l << d.description();
    return l;
}

QAudioDevice AudioEngine::deviceFor(int index) const
{
    const auto outs = QMediaDevices::audioOutputs();
    if (index <= 0 || index > outs.size())
        return QMediaDevices::defaultAudioOutput();
    return outs.at(index - 1);
}

AudioEngine::Voice *AudioEngine::primaryVoice() const
{
    for (Voice *v : m_voices)
        if (v->busy)
            return v;
    return nullptr;
}

QStringList AudioEngine::playingIds() const
{
    QStringList ids;
    for (const Voice *v : m_voices)
        if (v->busy && !ids.contains(v->id))
            ids << v->id;
    return ids;
}

bool AudioEngine::isPlaying(const QString &id) const
{
    return std::any_of(m_voices.cbegin(), m_voices.cend(),
                       [&](const Voice *v) { return v->busy && v->id == id; });
}

qint64 AudioEngine::positionMs() const
{
    if (const Voice *v = primaryVoice())
        return v->player->position();
    return 0;
}

qint64 AudioEngine::durationMs() const
{
    if (const Voice *v = primaryVoice())
        return v->player->duration();
    return 0;
}

qreal AudioEngine::progress() const
{
    const qint64 d = durationMs();
    return d > 0 ? qBound<qreal>(0.0, qreal(positionMs()) / d, 1.0) : 0.0;
}

qreal AudioEngine::progressOf(const QString &id) const
{
    for (const Voice *v : m_voices) {
        if (v->busy && v->id == id) {
            const qint64 dur = v->player->duration();
            return dur > 0 ? qBound<qreal>(0.0, qreal(v->player->position()) / dur, 1.0) : 0.0;
        }
    }
    return 0.0;
}

void AudioEngine::seek(qreal fraction)
{
    fraction = qBound<qreal>(0.0, fraction, 1.0);
    Voice *v = primaryVoice();
    if (!v)
        return;
    const qint64 d = v->player->duration();
    if (d <= 0)
        return;
    v->player->setPosition(qint64(fraction * d));
    emit positionChanged();
}

void AudioEngine::seekMs(qint64 ms)
{
    Voice *v = primaryVoice();
    if (!v)
        return;
    const qint64 d = v->player->duration();
    if (d <= 0)
        return;
    v->player->setPosition(qBound(qint64(0), ms, d));
    emit positionChanged();
}

bool AudioEngine::anyBusy() const
{
    return std::any_of(m_voices.cbegin(), m_voices.cend(), [](const Voice *v) { return v->busy; });
}

void AudioEngine::applyVolume(Voice *v)
{
    const qreal m = m_master * m_master;
    v->out->setVolume(float(m * qBound<qreal>(0.0, v->gain, 1.0)));
}

void AudioEngine::setMasterVolume(qreal v)
{
    v = qBound<qreal>(0.0, v, 1.0);
    if (qFuzzyCompare(v, m_master))
        return;
    m_master = v;
    QSettings().setValue("audio/master", m_master);
    for (Voice *voice : std::as_const(m_voices))
        applyVolume(voice);
    emit masterVolumeChanged();
}

void AudioEngine::setPlayMode(int m)
{
    m = qBound(0, m, 2);
    if (m == m_mode)
        return;
    m_mode = m;
    if (m_mode != Queue && !m_queue.isEmpty()) {
        m_queue.clear();
        emit queueChanged();
    }
    QSettings().setValue("audio/mode", m_mode);
    emit playModeChanged();
}

void AudioEngine::setOutputDeviceIndex(int i)
{
    if (i == m_deviceIndex)
        return;
    m_deviceIndex = i;
    const QAudioDevice dev = deviceFor(i);
    for (Voice *v : std::as_const(m_voices))
        v->out->setDevice(dev);
    emit outputDeviceIndexChanged();
}

AudioEngine::Voice *AudioEngine::acquire()
{
    for (Voice *v : std::as_const(m_voices))
        if (!v->busy)
            return v;

    if (m_voices.size() < kMaxVoices) {
        auto *v = new Voice;
        v->player = new QMediaPlayer(this);
        v->out = new QAudioOutput(this);
        v->out->setDevice(deviceFor(m_deviceIndex));
        v->player->setAudioOutput(v->out);
        connect(v->player, &QMediaPlayer::mediaStatusChanged, this,
                [this, v](QMediaPlayer::MediaStatus s) {
                    if (s == QMediaPlayer::EndOfMedia && v->busy)
                        release(v);
                });
        connect(v->player, &QMediaPlayer::errorOccurred, this,
                [this, v](QMediaPlayer::Error, const QString &msg) {
                    emit errorOccurred(msg);
                    if (v->busy)
                        release(v);
                });
        connect(v->player, &QMediaPlayer::positionChanged, this, [this, v](qint64) {
            if (v->busy)
                emit positionChanged();
        });
        connect(v->player, &QMediaPlayer::durationChanged, this, [this, v](qint64) {
            if (v->busy) {
                emit durationChanged();
                emit positionChanged();
            }
        });
        m_voices.append(v);
        return v;
    }

    Voice *oldest = m_voices.first();
    oldest->player->stop();
    return oldest;
}

void AudioEngine::startVoice(const QString &id, const QUrl &source, qreal gain)
{
    Voice *v = acquire();
    v->id = id;
    v->gain = gain;
    v->busy = true;
    applyVolume(v);
    v->player->setSource(QUrl());
    v->player->setSource(source);
    v->player->play();
    emit playingIdsChanged();
    emit positionChanged();
    emit durationChanged();
}

void AudioEngine::release(Voice *v)
{
    v->busy = false;
    v->id.clear();
    v->player->stop();
    emit playingIdsChanged();
    emit positionChanged();
    emit durationChanged();
    if (m_mode == Queue && !anyBusy())
        playNextInQueue();
}

void AudioEngine::playNextInQueue()
{
    if (m_queue.isEmpty())
        return;
    const QueuedItem it = m_queue.dequeue();
    emit queueChanged();
    startVoice(it.id, it.source, it.gain);
}

void AudioEngine::play(const QString &id, const QUrl &source, qreal gain)
{
    switch (m_mode) {
    case StopPrevious:
        if (isPlaying(id)) {
            stop(id);
            return;
        }
        stopAll();
        startVoice(id, source, gain);
        break;
    case Overlay:
        startVoice(id, source, gain);
        break;
    case Queue:
        if (!anyBusy()) {
            startVoice(id, source, gain);
        } else {
            m_queue.enqueue({id, source, gain});
            emit queueChanged();
        }
        break;
    }
}

void AudioEngine::stop(const QString &id)
{
    for (Voice *v : std::as_const(m_voices)) {
        if (v->busy && v->id == id) {
            v->busy = false;
            v->id.clear();
            v->player->stop();
        }
    }
    emit playingIdsChanged();
    emit positionChanged();
    emit durationChanged();
    if (m_mode == Queue && !anyBusy())
        playNextInQueue();
}

void AudioEngine::stopAll()
{
    if (!m_queue.isEmpty()) {
        m_queue.clear();
        emit queueChanged();
    }
    for (Voice *v : std::as_const(m_voices)) {
        if (v->busy) {
            v->busy = false;
            v->id.clear();
            v->player->stop();
        }
    }
    emit playingIdsChanged();
    emit positionChanged();
    emit durationChanged();
}
