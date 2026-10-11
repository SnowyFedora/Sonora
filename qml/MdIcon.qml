import QtQuick
import QtQuick.Shapes

// Иконка из SVG-пути 24×24, масштабируется до `size`.
Item {
    id: root
    property string path
    property color color: "black"
    property real size: 24

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: root.color
            strokeWidth: -1
            PathSvg { path: root.path }
        }
    }
}
