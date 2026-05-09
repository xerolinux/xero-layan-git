/*************************************************************************************
The MIT License (MIT)

Copyright (c) 2021 Arun Pk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
************************************************************************************/

import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQml

Item {
    id: control

    /*!
        \qmlproperty real CircularSlider::trackWidth
        This property holds the width of the track arc.
    */
    property int trackWidth: 20

    /*!
        \qmlproperty real CircularSlider::progressWidth
        This property holds the width of the progress arc.
    */
    property int progressWidth: 20

    /*!
        \qmlproperty real CircularSlider::handleWidth
        This property holds the width of the default slider handle.
    */
    property int handleWidth: 22

    /*!
        \qmlproperty real CircularSlider::handleHeight
        This property holds the height of the default slider handle.
    */
    property int handleHeight: 22

    /*!
        \qmlproperty real CircularSlider::handleRadius
        This property holds the corner radius used to draw a rounded rectangle for the slider handle.
    */
    property int handleRadius: 11

    /*!
        \qmlproperty CircularSlider::handleVerticalOffset
        This property defines the offset in which the handle should be placed.
     */
    property int handleVerticalOffset: 0

    /*!
        \qmlproperty real CircularSlider::startAngle
        This property holds the start angle of the slider.
        The range is from \c 0 degrees to \c 360 degrees.
    */
    property real startAngle: 0

    /*!
        \qmlproperty real CircularSlider::endAngle
        This property holds the end angle of the slider.
        The range is from \c 0 degrees to \c 360 degrees.
    */
    property real endAngle: 360

    /*!
        \qmlproperty real CircularSlider::minimumValue
        This property holds the minimum value of the slider.
        The default value is \c{0.0}.
    */
    property real minValue: 0.0

    /*!
        \qmlproperty real CircularSlider::maximumValue
        This property holds the minimum value of the slider.
        The default value is \c{1.0}.
    */
    property real maxValue: 1.0

    /*!
        \qmlproperty real CircularSlider::value
        This property holds the current value of the slider.
        The default value is \c{0.0}.
    */
    property real value: 0.0

    /*!
        \qmlproperty real CircularSlider::angle
        \readonly
        This property holds the angle of the handle.
        The range is from \c 0 degrees to \c 360 degrees.
    */
    readonly property alias angle: internal.angle

    /*!
        \qmlproperty enumeration CircularSlider::capStyle
        This property defines how the end points of lines are drawn. The default value is Qt.RoundCap.
     */
    property int capStyle: Qt.RoundCap

    /*!
        \qmlproperty real CircularSlider::trackColor
        This property holds the fill color for the track.
    */
    property color trackColor: "#505050"

    /*!
        \qmlproperty real CircularSlider::progressColor
        This property holds the fill color for the progress.
    */
    property color progressColor: "#3a4ec4"

    /*!
        \qmlproperty real CircularSlider::handleColor
        This property holds the fill color for the progress.
    */
    property color handleColor: "#fefefe"

    /*!
        \qmlproperty CircularSlider::stepSize
        This property holds the step size. The default value is 0.0
        The step size determines the amount by which the slider's value is increased and decreased when interacted.
        The step size is only respected when snap is set to value true
    */
    property real stepSize: 0.1

    /*!
        \qmlproperty CircularSlider::snap
        This property holds weather the value should be snapped or not.
        The default value is false.
    */
    property bool snap: false

    /*!
        \qmlproperty real CircularSlider::handle
        This property holds the custom handle of the dial.
    */
    property Component handle: null

    /*!
        \qmlproperty bool CircularSlider::pressed
        \readonly
        This property indicates whether the slider handle is being pressed.
    */
    readonly property alias pressed: trackMouse.pressed

    /*!
        \qmlproperty CircularSlider::hideTrack
        This property holds weather the track should be shown or not.
        The default value is false.
    */
    property bool hideTrack: false

    /*!
        \qmlproperty CircularSlider::hideProgress
        This property holds weather the progress should be shown or not.
        The default value is false.
    */
    property bool hideProgress: false

    /*!
        \qmlproperty CircularSlider::interactive
        This property describes whether the user can interact with the Flickable.
        A user cannot drag the handle or click on the slider that is not interactive.
        Slider can be used as a progress indicator by setting interactive to false.
        The default value is true.
    */
    property bool interactive: true

    /*!
        \qmlproperty CircularSlider::interactive
        This property holds the cursor shape for this mouse area.
        On platforms that do not display a mouse cursor this may have no effect.
        The default value is Qt.ArrowCursor.
    */
    property alias cursorShape: trackMouse.cursorShape

    implicitWidth: 250
    implicitHeight: 250

    Binding {
        target: control
        property: "value"
        value: control.snap ? internal.snappedValue : internal.mapFromValue(startAngle, endAngle, minValue, maxValue, internal.angleProxy)
        when: internal.setUpdatedValue
        restoreMode: Binding.RestoreBinding
    }

    QtObject {
        id: internal

        property var centerPt: Qt.point(control.width / 2, control.height / 2)
        property real baseRadius: Math.min(control.width, control.height) / 2 - Math.max(control.trackWidth, control.progressWidth) / 2
        property real actualSpanAngle: control.endAngle - control.startAngle
        property color transparentColor: "transparent"
        property color trackColor: control.trackColor
        property bool setUpdatedValue: false
        property real angleProxy: control.startAngle
        property real snappedValue: 0.0
        readonly property real angle: internal.mapFromValue(control.minValue, control.maxValue, control.startAngle, control.endAngle, control.value)

        function mapFromValue(inMin, inMax, outMin, outMax, inValue) {
            return (inValue - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
        }

        function updateAngle(angleVal) {
            if (angleVal < 0)
                angleVal += 360;

            if ((angleVal >= control.startAngle) && (angleVal <= control.endAngle)) {
                internal.setUpdatedValue = true;
                internal.angleProxy = Qt.binding(function() { return angleVal; });
                if(control.snap) {
                    var mappedValue = internal.mapFromValue(startAngle, endAngle, minValue, maxValue, internal.angleProxy)
                    var range = control.maxValue - control.minValue
                    var effectiveStep = 2
                    var actualVal = control.stepSize * Math.round(mappedValue / control.stepSize)
                    internal.snappedValue = actualVal
                }
                internal.setUpdatedValue = false;
            }
        }
    }

    // Track Shapes
    Shape {
        id: trackShape

        width: control.width
        height: control.height
        layer.enabled: true
        layer.samples: 8
        visible: !control.hideTrack

        ShapePath {
            id: trackShapePath

            strokeColor: control.trackColor
            fillColor: internal.transparentColor
            strokeWidth: control.trackWidth
            capStyle: control.capStyle

            PathAngleArc {
                radiusX: internal.baseRadius
                radiusY: internal.baseRadius
                centerX: control.width / 2
                centerY: control.height / 2
                startAngle: control.startAngle - 90
                sweepAngle: internal.actualSpanAngle
            }
        }
    }

    // Progress Shape
    Shape {
        id: progressShape

        width: control.width
        height: control.height
        layer.enabled: true
        layer.samples: 8
        visible: !control.hideProgress

        ShapePath {
            id: progressShapePath

            strokeColor: control.progressColor
            fillColor: internal.transparentColor
            strokeWidth: control.progressWidth
            capStyle: control.capStyle

            PathAngleArc {
                radiusX: internal.baseRadius
                radiusY: internal.baseRadius
                centerX: control.width / 2
                centerY: control.height / 2
                startAngle: control.startAngle - 90
                sweepAngle: control.angle - control.startAngle
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: control.interactive
        onClicked: {
            var outerRadius = Math.min(control.width, control.height)/ 2
            var innerRadius = outerRadius - Math.max(control.trackWidth, 20);
            var clickedDistance = (mouseX - internal.centerPt.x) * (mouseX - internal.centerPt.x) + (mouseY - internal.centerPt.y) * (mouseY - internal.centerPt.y);
            var innerRadius2 = (innerRadius * innerRadius);
            var outerRadius2 = (outerRadius * outerRadius);
            var isOutOfInnerRadius = clickedDistance > innerRadius2;
            var inInSideOuterRadius = clickedDistance <= outerRadius2;
            if (inInSideOuterRadius && isOutOfInnerRadius) {
                var angleDeg = Math.atan2(mouseY - internal.centerPt.y, mouseX - internal.centerPt.x) * 180 / Math.PI + 90;
                internal.updateAngle(angleDeg);
            }
        }
    }

    // Handle Item
    Item {
        id: handleItem
        visible: control.interactive

        x: control.width / 2 - width / 2
        y: control.height / 2 - height / 2
        // make sure that the slider handle is always on top as we can set custom track or progress items
        z: 2
        width: control.handleWidth
        height: control.handleHeight
        antialiasing: true
        transform: [
            Translate {
                y: -(Math.min(control.width, control.height) / 2) + Math.max(control.trackWidth, control.progressWidth) / 2 + control.handleVerticalOffset
            },
            Rotation {
                angle: control.angle
                origin.x: handleItem.width / 2
                origin.y: handleItem.height / 2
            }
        ]

        MouseArea {
            id: trackMouse
            enabled: control.interactive

            function getVal() {
                var handlePoint = mapToItem(control, trackMouse.mouseX, trackMouse.mouseY);
                // angle in degrees
                var angleDeg = Math.atan2(handlePoint.y - internal.centerPt.y, handlePoint.x - internal.centerPt.x) * 180 / Math.PI + 90;
                internal.updateAngle(angleDeg);
            }

            anchors.fill: parent
            onPositionChanged: getVal()
            onClicked: getVal()
            cursorShape: Qt.ArrowCursor
        }

        Loader {
            id: handleLoader

            sourceComponent: control.handle ? handle : handleComponent
        }
    }

    /// Default handle component
    Component {
        id: handleComponent

        Rectangle {
            width: control.handleWidth
            height: control.handleHeight
            color: control.handleColor
            radius: control.handleRadius
            antialiasing: true
        }
    }
}
