// Windows: RegisterHotKey + нативный фильтр событий (WM_HOTKEY).
// Не использует хуки клавиатуры → безопаснее для игр с античитами.
#include "IHotkeyBackend.h"

#include <QAbstractNativeEventFilter>
#include <QCoreApplication>

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

namespace {

UINT toVirtualKey(int key, bool keypad)
{
    if (key >= Qt::Key_A && key <= Qt::Key_Z)
        return UINT(key); // 'A'..'Z' совпадают с VK
    if (key >= Qt::Key_0 && key <= Qt::Key_9)
        return keypad ? UINT(VK_NUMPAD0 + (key - Qt::Key_0)) : UINT(key);
    if (key >= Qt::Key_F1 && key <= Qt::Key_F24)
        return UINT(VK_F1 + (key - Qt::Key_F1));

    switch (key) {
    case Qt::Key_Space: return VK_SPACE;
    case Qt::Key_Return:
    case Qt::Key_Enter: return VK_RETURN;
    case Qt::Key_Escape: return VK_ESCAPE;
    case Qt::Key_Tab: return VK_TAB;
    case Qt::Key_Backspace: return VK_BACK;
    case Qt::Key_Insert: return VK_INSERT;
    case Qt::Key_Delete: return VK_DELETE;
    case Qt::Key_Home: return VK_HOME;
    case Qt::Key_End: return VK_END;
    case Qt::Key_PageUp: return VK_PRIOR;
    case Qt::Key_PageDown: return VK_NEXT;
    case Qt::Key_Left: return VK_LEFT;
    case Qt::Key_Right: return VK_RIGHT;
    case Qt::Key_Up: return VK_UP;
    case Qt::Key_Down: return VK_DOWN;
    case Qt::Key_Plus: return keypad ? VK_ADD : VK_OEM_PLUS;
    case Qt::Key_Minus: return keypad ? VK_SUBTRACT : VK_OEM_MINUS;
    case Qt::Key_Asterisk: return VK_MULTIPLY;
    case Qt::Key_Slash: return keypad ? VK_DIVIDE : VK_OEM_2;
    case Qt::Key_Comma: return VK_OEM_COMMA;
    case Qt::Key_Period: return keypad ? VK_DECIMAL : VK_OEM_PERIOD;
    case Qt::Key_Semicolon: return VK_OEM_1;
    case Qt::Key_BracketLeft: return VK_OEM_4;
    case Qt::Key_BracketRight: return VK_OEM_6;
    case Qt::Key_MediaPlay:
    case Qt::Key_MediaTogglePlayPause: return VK_MEDIA_PLAY_PAUSE;
    case Qt::Key_MediaNext: return VK_MEDIA_NEXT_TRACK;
    case Qt::Key_MediaPrevious: return VK_MEDIA_PREV_TRACK;
    default: return 0;
    }
}

class WinHotkeyBackend final : public IHotkeyBackend, public QAbstractNativeEventFilter {
public:
    explicit WinHotkeyBackend(QObject *parent)
        : IHotkeyBackend(parent)
    {
        QCoreApplication::instance()->installNativeEventFilter(this);
    }

    ~WinHotkeyBackend() override
    {
        for (int id : std::as_const(m_registered))
            UnregisterHotKey(nullptr, id);
        if (auto *app = QCoreApplication::instance())
            app->removeNativeEventFilter(this);
    }

    QString name() const override { return QStringLiteral("Win32 RegisterHotKey"); }

    bool registerHotkey(int id, const KeyCombo &c) override
    {
        const UINT vk = toVirtualKey(c.key, c.keypad);
        if (!vk)
            return false;
        UINT mods = MOD_NOREPEAT;
        if (c.mods.testFlag(Qt::ControlModifier)) mods |= MOD_CONTROL;
        if (c.mods.testFlag(Qt::AltModifier)) mods |= MOD_ALT;
        if (c.mods.testFlag(Qt::ShiftModifier)) mods |= MOD_SHIFT;
        if (c.mods.testFlag(Qt::MetaModifier)) mods |= MOD_WIN;

        if (!RegisterHotKey(nullptr, id, mods, vk))
            return false; // сочетание занято
        m_registered.append(id);
        return true;
    }

    void unregisterHotkey(int id) override
    {
        if (m_registered.removeOne(id))
            UnregisterHotKey(nullptr, id);
    }

    bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *) override
    {
        if (eventType == "windows_generic_MSG") {
            const MSG *msg = static_cast<MSG *>(message);
            if (msg->message == WM_HOTKEY) {
                emit activated(int(msg->wParam));
                return true;
            }
        }
        return false;
    }

private:
    QList<int> m_registered;
};

} // namespace

std::unique_ptr<IHotkeyBackend> createHotkeyBackend(QObject *parent)
{
    return std::make_unique<WinHotkeyBackend>(parent);
}
