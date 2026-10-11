#include "AppController.h"

#include <QFileDialog>
#include <QFileInfo>
#include <QCryptographicHash>
#include <QSettings>
#include <QUrl>

namespace {
const QString kStopAllId = QStringLiteral("app:stopAll");
}

AppController::AppController(QObject *parent)
    : QObject(parent)
{
    QSettings st;
    m_alwaysOnTop = st.value("window/alwaysOnTop", false).toBool();
    m_stopAllHotkey = st.value("hotkeys/stopAll", "Ctrl+Alt+S").toString();

    connect(&m_hotkeys, &HotkeyManager::triggered, this, [this](const QString &id) {
        if (id == kStopAllId)
            stopPlayback();
        else
            play(id);
    });
    connect(&m_hotkeys, &HotkeyManager::registrationFailed, this,
            [this](const QString &, const QString &seq) {
                emit toast(tr("Не удалось занять сочетание %1").arg(seq));
            });
    connect(&m_library, &SoundLibrary::hotkeysChanged, this, &AppController::syncHotkeys);

    // Когда ничего не играет — сбросить флаг
    connect(&m_engine, &AudioEngine::playingIdsChanged, this, [this] {
        emit nowPlayingChanged();
    });

    m_library.load();
    syncHotkeys();
}

void AppController::syncHotkeys()
{
    m_hotkeys.clearAll();
    m_hotkeys.assign(kStopAllId, m_stopAllHotkey);
    for (const Sound &s : m_library.all())
        if (!s.hotkey.isEmpty())
            m_hotkeys.assign(s.id, s.hotkey);
}

void AppController::setAlwaysOnTop(bool v)
{
    if (v == m_alwaysOnTop)
        return;
    m_alwaysOnTop = v;
    QSettings().setValue("window/alwaysOnTop", v);
    emit alwaysOnTopChanged();
}

void AppController::setStopAllHotkey(const QString &seq)
{
    if (seq == m_stopAllHotkey)
        return;
    m_stopAllHotkey = seq;
    QSettings().setValue("hotkeys/stopAll", seq);
    m_hotkeys.assign(kStopAllId, seq);
    emit stopAllHotkeyChanged();
}

bool AppController::isPlaying() const
{
    if (m_nowId.isEmpty())
        return false;
    return m_engine.isPlaying(m_nowId) || m_engine.playingIds().contains(m_nowId);
}

void AppController::setNowPlaying(const QString &id)
{
    m_nowId = id;
    if (const Sound *s = m_library.find(id)) {
        m_nowTitle = s->title;
        m_nowArtist = s->folder; // folder as secondary line
    } else {
        m_nowTitle.clear();
        m_nowArtist.clear();
    }
    emit nowPlayingChanged();
}

void AppController::play(const QString &soundId)
{
    const Sound *s = m_library.find(soundId);
    if (!s)
        return;
    m_engine.play(s->id, QUrl::fromLocalFile(s->path), s->volume);
    m_library.markPlayed(s->id);
    setNowPlaying(soundId);

    // Обновить очередь = вся библиотека по порядку title (простая навигация next/prev)
    m_queue.clear();
    for (const Sound &x : m_library.all())
        m_queue.append(x.id);
    m_queueIndex = m_queue.indexOf(soundId);
}

void AppController::playNext()
{
    if (m_queue.isEmpty())
        return;
    int i = m_queueIndex + 1;
    if (i >= m_queue.size())
        i = 0;
    play(m_queue.at(i));
}

void AppController::playPrevious()
{
    if (m_queue.isEmpty())
        return;
    int i = m_queueIndex - 1;
    if (i < 0)
        i = m_queue.size() - 1;
    play(m_queue.at(i));
}

void AppController::stopPlayback()
{
    m_engine.stopAll();
    emit nowPlayingChanged();
}

void AppController::toggleFavorite(const QString &soundId)
{
    if (const Sound *s = m_library.find(soundId))
        m_library.setFavorite(soundId, !s->favorite);
}

int AppController::addFolder(const QUrl &folderUrl)
{
    const int n = m_library.addFolder(folderUrl);
    emit toast(n > 0 ? tr("Добавлено: %1").arg(n) : tr("Новых файлов нет"));
    return n;
}

int AppController::addUrls(const QList<QUrl> &urls)
{
    const int n = m_library.addUrls(urls);
    emit toast(n > 0 ? tr("Добавлено: %1").arg(n) : tr("Новых файлов нет"));
    return n;
}

void AppController::pickFolder()
{
    QFileDialog dlg(nullptr, tr("Папка с музыкой"));
    dlg.setFileMode(QFileDialog::Directory);
    dlg.setOption(QFileDialog::ShowDirsOnly, true);
    dlg.setOption(QFileDialog::DontResolveSymlinks, true);
    dlg.setLabelText(QFileDialog::Accept, tr("Выбрать"));
    if (dlg.exec() != QDialog::Accepted)
        return;
    const QStringList dirs = dlg.selectedFiles();
    if (!dirs.isEmpty())
        addFolder(QUrl::fromLocalFile(dirs.first()));
}

void AppController::pickFiles()
{
    QFileDialog dlg(nullptr, tr("Музыкальные файлы"));
    dlg.setFileMode(QFileDialog::ExistingFiles);
    dlg.setNameFilter(tr("Аудио (*.mp3 *.wav *.ogg *.flac *.m4a *.opus *.aac *.wma *.aiff);;Все (*)"));
    dlg.setLabelText(QFileDialog::Accept, tr("Добавить"));
    if (dlg.exec() != QDialog::Accepted)
        return;
    QList<QUrl> urls;
    for (const QString &path : dlg.selectedFiles())
        urls.append(QUrl::fromLocalFile(path));
    if (!urls.isEmpty())
        addUrls(urls);
}

void AppController::pickImage()
{
    const QString path = QFileDialog::getOpenFileName(
        nullptr, tr("Изображение"), QString(),
        tr("Изображения (*.png *.jpg *.jpeg *.webp *.bmp)"));
    if (!path.isEmpty())
        m_theme.seedFromImage(QUrl::fromLocalFile(path));
}


void AppController::openPaths(const QStringList &paths)
{
    if (paths.isEmpty())
        return;

    QList<QUrl> fileUrls;
    QStringList playIds;

    for (QString raw : paths) {
        raw = raw.trimmed();
        if (raw.isEmpty())
            continue;
        // file:// URI от некоторых DE
        if (raw.startsWith(QLatin1String("file:"), Qt::CaseInsensitive))
            raw = QUrl(raw).toLocalFile();

        const QFileInfo fi(raw);
        if (!fi.exists())
            continue;

        if (fi.isDir()) {
            addFolder(QUrl::fromLocalFile(fi.absoluteFilePath()));
            continue;
        }
        if (fi.isFile()) {
            const QString abs = fi.absoluteFilePath();
            fileUrls.append(QUrl::fromLocalFile(abs));
            const QString id = QString::fromLatin1(
                QCryptographicHash::hash(abs.toUtf8(), QCryptographicHash::Sha1).toHex().left(12));
            playIds.append(id);
        }
    }

    if (!fileUrls.isEmpty())
        addUrls(fileUrls);

    // Воспроизвести первый добавленный/существующий трек
    for (const QString &id : playIds) {
        if (m_library.find(id)) {
            play(id);
            break;
        }
    }
}

QString AppController::assignHotkey(const QString &soundId, const QString &sequence)
{
    if (!sequence.isEmpty()) {
        const QString other = m_hotkeys.conflictFor(sequence, soundId);
        if (!other.isEmpty())
            return tr("Сочетание уже используется");
    }
    if (!m_hotkeys.assign(soundId, sequence))
        return tr("Сочетание недоступно");
    m_library.setHotkey(soundId, sequence);
    return {};
}
