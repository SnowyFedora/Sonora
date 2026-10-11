#include "ThemeEngine.h"

#include <QGuiApplication>
#include <QImage>
#include <QPalette>
#include <QSettings>
#include <QStyleHints>
#include <algorithm>
#include <array>
#include <cmath>

namespace {

constexpr double kPi = 3.14159265358979323846;

double encodeSrgb(double v)
{
    return v <= 0.0031308 ? 12.92 * v : 1.055 * std::pow(v, 1.0 / 2.4) - 0.055;
}
double decodeSrgb(double v)
{
    return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4);
}

struct Oklch {
    double L, C, h; // h в радианах
};

Oklch toOklch(const QColor &c)
{
    const double r = decodeSrgb(c.redF()), g = decodeSrgb(c.greenF()), b = decodeSrgb(c.blueF());
    const double l = std::cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const double m = std::cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const double s = std::cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    const double L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s;
    const double a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s;
    const double bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s;
    return {L, std::hypot(a, bb), std::atan2(bb, a)};
}

// Возвращает false, если цвет вне гаммы sRGB
bool fromOklch(double L, double C, double h, QColor &out)
{
    const double a = C * std::cos(h), b = C * std::sin(h);
    const double l_ = L + 0.3963377774 * a + 0.2158037573 * b;
    const double m_ = L - 0.1055613458 * a - 0.0638541728 * b;
    const double s_ = L - 0.0894841775 * a - 1.2914855480 * b;
    const double l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    const double r = +4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    const double g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    const double bl = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;
    constexpr double eps = 1e-4;
    const bool inGamut = r >= -eps && r <= 1 + eps && g >= -eps && g <= 1 + eps && bl >= -eps && bl <= 1 + eps;
    auto cl = [](double v) { return std::clamp(v, 0.0, 1.0); };
    out = QColor::fromRgbF(encodeSrgb(cl(r)), encodeSrgb(cl(g)), encodeSrgb(cl(bl)));
    return inGamut;
}

// Тон 0..100 (как CIE L*) -> OKLab L (для нейтральных точно: L = cbrt(Y))
double toneToL(double tone)
{
    tone = std::clamp(tone, 0.0, 100.0);
    const double y = tone > 8.0 ? std::pow((tone + 16.0) / 116.0, 3.0) : tone / 903.3;
    return std::cbrt(y);
}

struct TonalPalette {
    double hue;    // радианы
    double chroma; // OKLCH

    QColor tone(int t) const
    {
        if (t >= 100) return Qt::white;
        if (t <= 0) return Qt::black;
        const double L = toneToL(t);
        QColor c;
        if (fromOklch(L, chroma, hue, c))
            return c;
        // gamut mapping: уменьшаем chroma бисекцией
        double lo = 0.0, hi = chroma;
        for (int i = 0; i < 14; ++i) {
            const double mid = (lo + hi) / 2;
            QColor tmp;
            if (fromOklch(L, mid, hue, tmp)) lo = mid; else hi = mid;
        }
        fromOklch(L, lo, hue, c);
        return c;
    }
};

QVariantMap buildScheme(const QColor &seed, bool dark)
{
    const Oklch s = toOklch(seed);
    const double hue = s.h;
    const double primaryChroma = std::clamp(s.C, 0.12, 0.17);

    const TonalPalette P{hue, primaryChroma};
    const TonalPalette S{hue, 0.045};
    const TonalPalette T{hue + 60.0 * kPi / 180.0, 0.07};
    const TonalPalette N{hue, 0.012};
    const TonalPalette NV{hue, 0.024};
    const TonalPalette E{29.0 * kPi / 180.0, 0.17};

    QVariantMap m;
    auto set = [&m](const char *k, const QColor &c) { m.insert(QLatin1String(k), c); };

    // Текст: чёрный только в светлой теме, белый — в тёмной (без тональных «грязных» оттенков)
    const QColor textPrimary   = dark ? QColor(255, 255, 255) : QColor(0, 0, 0);
    const QColor textSecondary = dark ? QColor(220, 220, 220) : QColor(60, 60, 60);

    if (!dark) {
        set("primary", P.tone(40));             set("onPrimary", P.tone(100));
        set("primaryContainer", P.tone(90));    set("onPrimaryContainer", P.tone(10));
        set("secondary", S.tone(40));           set("onSecondary", S.tone(100));
        set("secondaryContainer", S.tone(90));  set("onSecondaryContainer", S.tone(10));
        set("tertiary", T.tone(40));            set("onTertiary", T.tone(100));
        set("tertiaryContainer", T.tone(90));   set("onTertiaryContainer", T.tone(10));
        set("error", E.tone(40));               set("onError", E.tone(100));
        set("errorContainer", E.tone(90));      set("onErrorContainer", E.tone(10));
        set("background", N.tone(98));          set("onBackground", textPrimary);
        set("surface", N.tone(98));             set("onSurface", textPrimary);
        set("surfaceVariant", NV.tone(90));     set("onSurfaceVariant", textSecondary);
        set("outline", NV.tone(50));            set("outlineVariant", NV.tone(80));
        set("surfaceContainerLowest", N.tone(100));
        set("surfaceContainerLow", N.tone(96));
        set("surfaceContainer", N.tone(94));
        set("surfaceContainerHigh", N.tone(92));
        set("surfaceContainerHighest", N.tone(90));
        set("inverseSurface", N.tone(20));      set("inverseOnSurface", N.tone(95));
        set("inversePrimary", P.tone(80));
    } else {
        set("primary", P.tone(80));             set("onPrimary", P.tone(20));
        set("primaryContainer", P.tone(30));    set("onPrimaryContainer", QColor(255, 255, 255));
        set("secondary", S.tone(80));           set("onSecondary", S.tone(20));
        set("secondaryContainer", S.tone(30));  set("onSecondaryContainer", QColor(255, 255, 255));
        set("tertiary", T.tone(80));            set("onTertiary", T.tone(20));
        set("tertiaryContainer", T.tone(30));   set("onTertiaryContainer", QColor(255, 255, 255));
        set("error", E.tone(80));               set("onError", E.tone(20));
        set("errorContainer", E.tone(30));      set("onErrorContainer", QColor(255, 255, 255));
        set("background", N.tone(6));           set("onBackground", textPrimary);
        set("surface", N.tone(6));              set("onSurface", textPrimary);
        set("surfaceVariant", NV.tone(30));     set("onSurfaceVariant", textSecondary);
        set("outline", NV.tone(60));            set("outlineVariant", NV.tone(30));
        set("surfaceContainerLowest", N.tone(4));
        set("surfaceContainerLow", N.tone(10));
        set("surfaceContainer", N.tone(12));
        set("surfaceContainerHigh", N.tone(17));
        set("surfaceContainerHighest", N.tone(22));
        set("inverseSurface", N.tone(90));      set("inverseOnSurface", N.tone(20));
        set("inversePrimary", P.tone(40));
    }
    return m;
}

QColor lerp(const QColor &a, const QColor &b, double t)
{
    return QColor::fromRgbF(a.redF() + (b.redF() - a.redF()) * t,
                            a.greenF() + (b.greenF() - a.greenF()) * t,
                            a.blueF() + (b.blueF() - a.blueF()) * t);
}

} // namespace

ThemeEngine::ThemeEngine(QObject *parent)
    : QObject(parent)
{
    QSettings st;
    m_mode = st.value("theme/mode", 0).toInt();
    m_seed = QColor(st.value("theme/seed", "#6750A4").toString());
    if (!m_seed.isValid())
        m_seed = QColor("#6750A4");

    m_anim.setStartValue(0.0);
    m_anim.setEndValue(1.0);
    m_anim.setDuration(380);
    m_anim.setEasingCurve(QEasingCurve(QEasingCurve::BezierSpline));
    {
        QEasingCurve c(QEasingCurve::BezierSpline);
        c.addCubicBezierSegment({0.2, 0.0}, {0.0, 1.0}, {1.0, 1.0}); // emphasized
        m_anim.setEasingCurve(c);
    }
    connect(&m_anim, &QVariantAnimation::valueChanged, this, [this](const QVariant &v) {
        const double t = v.toDouble();
        QVariantMap cur;
        for (auto it = m_target.cbegin(); it != m_target.cend(); ++it)
            cur.insert(it.key(), lerp(m_from.value(it.key()).value<QColor>(), it.value().value<QColor>(), t));
        m_current = cur;
        emit schemeChanged();
    });

    if (auto *hints = QGuiApplication::styleHints()) {
        connect(hints, &QStyleHints::colorSchemeChanged, this, [this] {
            if (m_mode == 0)
                refresh(true);
        });
    }
    refresh(false);
}

bool ThemeEngine::resolveDark() const
{
    if (m_mode == 1) return false;
    if (m_mode == 2) return true;
    if (auto *hints = QGuiApplication::styleHints())
        return hints->colorScheme() == Qt::ColorScheme::Dark;
    return false;
}

void ThemeEngine::refresh(bool animate)
{
    const bool dark = resolveDark();
    const bool darkChangedNow = dark != m_dark;
    m_dark = dark;
    m_target = buildScheme(m_seed, dark);

    if (!animate || m_current.isEmpty()) {
        m_anim.stop();
        m_current = m_target;
        emit schemeChanged();
    } else {
        m_from = m_current; // продолжаем плавно с текущего кадра
        m_anim.stop();
        m_anim.start();
    }
    if (darkChangedNow)
        emit darkChanged();
}

void ThemeEngine::setSeedColor(const QColor &c)
{
    if (!c.isValid() || c == m_seed)
        return;
    m_seed = c;
    QSettings().setValue("theme/seed", m_seed.name());
    emit seedColorChanged();
    refresh(true);
}

void ThemeEngine::setMode(int mode)
{
    mode = std::clamp(mode, 0, 2);
    if (mode == m_mode)
        return;
    m_mode = mode;
    QSettings().setValue("theme/mode", m_mode);
    emit modeChanged();
    refresh(true);
}

void ThemeEngine::useSystemAccent()
{
    // Qt 6.6+: системный акцент (Windows accent / GNOME / KDE)
    setSeedColor(QGuiApplication::palette().color(QPalette::Accent));
}

bool ThemeEngine::seedFromImage(const QUrl &imageUrl)
{
    QImage img(imageUrl.toLocalFile());
    if (img.isNull())
        return false;
    img = img.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation)
              .convertToFormat(QImage::Format_RGB32);

    // Группируем по оттенку; побеждает самая «насыщенная и населённая» корзина.
    constexpr int bins = 24;
    std::array<double, bins> score{};
    std::array<double, bins> sumSin{}, sumCos{};
    for (int y = 0; y < img.height(); ++y) {
        for (int x = 0; x < img.width(); ++x) {
            const Oklch p = toOklch(QColor(img.pixel(x, y)));
            if (p.L < 0.2 || p.L > 0.95 || p.C < 0.03)
                continue;
            double h = p.h < 0 ? p.h + 2 * kPi : p.h;
            const int b = std::min(bins - 1, int(h / (2 * kPi) * bins));
            const double w = p.C * p.C;
            score[b] += w;
            sumSin[b] += std::sin(p.h) * w;
            sumCos[b] += std::cos(p.h) * w;
        }
    }
    const int best = int(std::max_element(score.begin(), score.end()) - score.begin());
    if (score[best] <= 0.0)
        return false;
    const double hue = std::atan2(sumSin[best], sumCos[best]);
    QColor seed;
    fromOklch(0.6, 0.15, hue, seed);
    setSeedColor(seed);
    return true;
}

QVariantList ThemeEngine::presetSeeds() const
{
    static const char *colors[] = {"#6750A4", "#3F6FD8", "#0B8A8F", "#2E8B57",
                                   "#C28A00", "#D9531E", "#C2185B", "#7B5E57"};
    QVariantList l;
    for (const char *c : colors)
        l << QColor(c);
    return l;
}
