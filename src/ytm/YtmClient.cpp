#include "YtmClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QUrl>

YtmClient::YtmClient(QObject *parent)
    : QObject(parent)
{
    m_status = tr("YouTube Music");
    QMetaObject::invokeMethod(this, [this] { checkDeps(); }, Qt::QueuedConnection);
}

QString YtmClient::pythonBin() const
{
    return QStringLiteral("python3");
}

QString YtmClient::scriptPath() const
{
    const QString appDir = QCoreApplication::applicationDirPath();
    const QStringList candidates = {
        appDir + QStringLiteral("/../share/sonora/scripts/ytm.py"),
        appDir + QStringLiteral("/scripts/ytm.py"),
        QDir(appDir + QStringLiteral("/../..")).absoluteFilePath(QStringLiteral("scripts/ytm.py")),
        QDir::current().absoluteFilePath(QStringLiteral("scripts/ytm.py")),
    };
    for (const QString &p : candidates) {
        if (QFileInfo::exists(p))
            return QFileInfo(p).absoluteFilePath();
    }
    QDir d(appDir);
    for (int i = 0; i < 8; ++i) {
        const QString tryPath = d.filePath(QStringLiteral("scripts/ytm.py"));
        if (QFileInfo::exists(tryPath))
            return QFileInfo(tryPath).absoluteFilePath();
        if (!d.cdUp())
            break;
    }
    return QStringLiteral("scripts/ytm.py");
}

void YtmClient::setBusy(bool v)
{
    if (m_busy == v)
        return;
    m_busy = v;
    emit busyChanged();
}

void YtmClient::setStatus(const QString &s)
{
    if (m_status == s)
        return;
    m_status = s;
    emit statusChanged();
}

void YtmClient::setPlaying(bool v)
{
    if (m_playing == v)
        return;
    m_playing = v;
    emit nowPlayingChanged();
}

void YtmClient::run(const QStringList &args, const std::function<void(const QJsonValue &)> &onOk)
{
    if (m_proc) {
        m_proc->kill();
        m_proc->deleteLater();
        m_proc = nullptr;
    }
    setBusy(true);
    auto *p = new QProcess(this);
    m_proc = p;
    p->setProcessChannelMode(QProcess::MergedChannels);
    QStringList fullArgs = { scriptPath() };
    fullArgs.append(args);

    connect(p, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished), this,
            [this, p, onOk](int, QProcess::ExitStatus) {
                const QByteArray out = p->readAllStandardOutput().trimmed();
                if (m_proc == p)
                    m_proc = nullptr;
                p->deleteLater();
                setBusy(false);

                QJsonParseError err;
                const auto doc = QJsonDocument::fromJson(out, &err);
                if (err.error != QJsonParseError::NoError || !doc.isObject()) {
                    const QString msg = out.isEmpty()
                        ? tr("Пустой ответ ytm.py — установи: pip install -r requirements-ytm.txt")
                        : QString::fromUtf8(out.left(500));
                    setStatus(tr("Ошибка"));
                    emit errorOccurred(msg);
                    return;
                }
                const QJsonObject root = doc.object();
                if (!root.value(QStringLiteral("ok")).toBool()) {
                    const QString e = root.value(QStringLiteral("error")).toString();
                    setStatus(tr("Ошибка"));
                    emit errorOccurred(e.isEmpty() ? tr("ytm.py failed") : e);
                    return;
                }
                onOk(root.value(QStringLiteral("data")));
            });

    connect(p, &QProcess::errorOccurred, this, [this, p](QProcess::ProcessError) {
        if (m_proc == p)
            m_proc = nullptr;
        setBusy(false);
        setStatus(tr("Python не запущен"));
        emit errorOccurred(tr("Не удалось запустить python3: %1").arg(p->errorString()));
        p->deleteLater();
    });

    p->start(pythonBin(), fullArgs);
}

void YtmClient::checkDeps()
{
    setStatus(tr("Проверка…"));
    run({QStringLiteral("check")}, [this](const QJsonValue &) {
        m_available = true;
        emit availableChanged();
        setStatus(tr("YouTube Music готов"));
    });
}

void YtmClient::search(const QString &query)
{
    setStatus(tr("Поиск…"));
    run({QStringLiteral("search"), query, QStringLiteral("25")}, [this](const QJsonValue &data) {
        m_tracks.clear();
        for (const QJsonValue &v : data.toArray())
            m_tracks.append(v.toVariant());
        emit tracksChanged();
        setStatus(tr("Найдено: %1").arg(m_tracks.size()));
    });
}

void YtmClient::loadHome()
{
    setStatus(tr("Загрузка…"));
    run({QStringLiteral("home"), QStringLiteral("30")}, [this](const QJsonValue &data) {
        m_tracks.clear();
        for (const QJsonValue &v : data.toArray())
            m_tracks.append(v.toVariant());
        emit tracksChanged();
        setStatus(tr("Для тебя · %1").arg(m_tracks.size()));
    });
}

void YtmClient::playTrack(const QString &videoId, const QString &title, const QString &artist)
{
    if (videoId.isEmpty())
        return;
    m_curId = videoId;
    m_curTitle = title;
    m_curArtist = artist;
    m_playing = false;
    emit nowPlayingChanged();
    setStatus(tr("Получение потока…"));
    run({QStringLiteral("stream"), videoId}, [this, videoId, title, artist](const QJsonValue &data) {
        const QJsonObject o = data.toObject();
        const QString url = o.value(QStringLiteral("url")).toString();
        if (url.isEmpty()) {
            emit errorOccurred(tr("Нет URL потока"));
            return;
        }
        const QString t = o.value(QStringLiteral("title")).toString();
        if (!t.isEmpty())
            m_curTitle = t;
        m_curArtist = artist;
        m_curId = videoId;
        m_playing = true;
        emit nowPlayingChanged();
        setStatus(m_curTitle);
        if (m_playCb)
            m_playCb(QStringLiteral("ytm:") + videoId, QUrl(url), 1.0);
    });
}

void YtmClient::stop()
{
    m_playing = false;
    emit nowPlayingChanged();
    if (m_stopCb)
        m_stopCb();
}
