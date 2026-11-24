/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Row of a "···" menu or gear menu: same layout as the KDE Connect pane
// (22 px icon, margins, rounded 50 % white highlight on hover)
Item {
    id: lp
    property string libelle: ""
    property string icone: ""
    signal choisie()
    Layout.fillWidth: true
    implicitWidth: lpRang.implicitWidth + (Kirigami.Units.smallSpacing + 6) * 2
    implicitHeight: Math.max(22, lpTexte.implicitHeight) + Kirigami.Units.smallSpacing * 2
    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Kirigami.Units.smallSpacing
        color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff")
        border.width: 1
        border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000")
        opacity: lpSouris.containsMouse ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
    Row {
        id: lpRang
        x: Kirigami.Units.smallSpacing + 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: Kirigami.Units.smallSpacing + 6
        Kirigami.Icon {
            source: lp.icone
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            id: lpTexte
            text: lp.libelle
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }
    MouseArea {
        id: lpSouris
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: lp.choisie()
    }
}
