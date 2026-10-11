#include "HotkeyManager.h"

#include <QDebug>
#include <QKeySequence>

namespace {

// Заглушка для платформ, где глобальные хоткеи ещё не реализованы.
// X11: XGrabKey (xcb) · Wayland: xdg-desktop-portal GlobalShortcuts (D-Bus) · macOS: Carbon RegisterEventHotKey
class NullHotkeyBackend final : public IHotkeyBackend {
public:
    using IHotkeyBackend::IHotkeyBackend;
    QString name() const override { return QStringLiteral("none (TODO)"); }
    bool registerHotkey(int, const KeyCombo &) override
    {
        qWarning() << "Global hotkeys are not implemented on this platform yet";
        return false;
    }
    void unregisterHotkey(int) override {}
};

} // namespace

#ifndef Q_OS_WIN
std::unique_ptr<IHotkeyBackend> createHotkeyBackend(QObject *parent)
{
    return std::make_unique<NullHotkeyBackend>(parent);
}
#endif
// Windows-реализация createHotkeyBackend() живёт в HotkeyBackendWin.cpp

HotkeyManager::HotkeyManager(QObject *parent)
    : QObject(parent)
    , m_backend(createHotkeyBackend(this))
{
    connect(m_backend.get(), &IHotkeyBackend::activated, this, [this](int numeric) {
        const auto it = m_names.constFind(numeric);
        if (it != m_names.cend())
            emit triggered(it.value());
    });
}

bool HotkeyManager::parse(const QString &sequence, KeyCombo &out)
{
    const QKeySequence ks(sequence, QKeySequence::PortableText);
    if (ks.isEmpty())
        return false;
    const QKeyCombination c = ks[0];
    out.mods = c.keyboardModifiers();
    out.keypad = out.mods.testFlag(Qt::KeypadModifier);
    out.mods &= ~Qt::KeyboardModifiers(Qt::KeypadModifier);
    out.key = int(c.key());
    return out.key != 0 && out.key != int(Qt::Key_unknown);
}

QString HotkeyManager::conflictFor(const QString &sequence, const QString &exceptId) const
{
    const QString norm = QKeySequence(sequence, QKeySequence::PortableText).toString(QKeySequence::PortableText);
    if (norm.isEmpty())
        return {};
    for (auto it = m_sequences.cbegin(); it != m_sequences.cend(); ++it)
        if (it.key() != exceptId && it.value() == norm)
            return it.key();
    return {};
}

bool HotkeyManager::assign(const QString &id, const QString &sequence)
{
    clear(id);
    if (sequence.trimmed().isEmpty())
        return true;

    KeyCombo combo;
    if (!parse(sequence, combo)) {
        emit registrationFailed(id, sequence);
        return false;
    }
    const int numeric = m_nextId++;
    if (!m_backend->registerHotkey(numeric, combo)) {
        emit registrationFailed(id, sequence); // занято другим приложением или ОС
        return false;
    }
    m_ids.insert(id, numeric);
    m_names.insert(numeric, id);
    m_sequences.insert(id, QKeySequence(sequence, QKeySequence::PortableText).toString(QKeySequence::PortableText));
    return true;
}

void HotkeyManager::clear(const QString &id)
{
    const auto it = m_ids.find(id);
    if (it == m_ids.end())
        return;
    m_backend->unregisterHotkey(it.value());
    m_names.remove(it.value());
    m_sequences.remove(id);
    m_ids.erase(it);
}

void HotkeyManager::clearAll()
{
    const QStringList keys = m_ids.keys();
    for (const QString &id : keys)
        clear(id);
}
