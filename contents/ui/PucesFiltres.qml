/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Effects
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Filter chips in the theme style (translucent white + thin border),
// the active chip is Fenestra royal blue (#0055A4)
Item {
    id: puces

    property string actif: "All"
    signal choisir(string filtre)
    signal retour()   // 1.2: back arrow, as in the Menu 11 search

    implicitHeight: Math.ceil(Kirigami.Units.gridUnit * 1.8) + 8   // 1.2: Menu 11 capsules

    readonly property var filtres: [
        { cle: "All",     nom: i18n("All") },
        { cle: "Apps",    nom: i18n("Apps") },
        { cle: "Docs",    nom: i18n("Docs") },
        { cle: "Images",  nom: i18n("Images") },
        { cle: "Folders", nom: i18n("Folders") },
        { cle: "Web",     nom: i18n("Web") }
    ]

    // 1.2: back arrow to the left of the capsules, as in the Menu 11 search
    Item {
        id: boutonRetour
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Math.ceil(Kirigami.Units.gridUnit * 2)
        height: width
        Accessible.role: Accessible.Button
        Accessible.name: i18n("Back")

        Rectangle {
            anchors.fill: parent
            radius: 5
            color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff")
            border.width: 1
            border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000")
            opacity: retourSouris.containsMouse ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        Item {   // real Fluent arrow (ic_fluent_arrow_left_24_regular), tinted like the text
            id: flecheRetour
            anchors.centerIn: parent
            width: Kirigami.Units.iconSizes.smallMedium
            height: width
            Image {
                id: flecheForme
                anchors.fill: parent
                source: Qt.resolvedUrl("../icons/fluent/arrow-left.svg")
                sourceSize.width: Math.max(1, flecheRetour.width) * 2
                sourceSize.height: Math.max(1, flecheRetour.height) * 2
                smooth: true
                visible: false
            }
            Rectangle {
                id: flecheCouleur
                anchors.fill: parent
                color: Kirigami.Theme.textColor
                visible: false
            }
            MultiEffect {
                anchors.fill: parent
                source: flecheCouleur
                maskEnabled: true
                maskSource: flecheForme
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
                opacity: 0.8   // 2.0: same dark gray as the KDE Connect icon (theme text at 80 %)
            }
        }
        MouseArea {
            id: retourSouris
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: puces.retour()
        }
        PC3.ToolTip.text: i18n("Back")
        PC3.ToolTip.visible: retourSouris.containsMouse
        PC3.ToolTip.delay: 400
    }

    Flickable {
        anchors.left: boutonRetour.right
        anchors.leftMargin: Kirigami.Units.smallSpacing
        anchors.right: parent.right
        anchors.rightMargin: Math.ceil(Kirigami.Units.gridUnit * 2) + Kirigami.Units.smallSpacing   // room for the gear (placed by the window)
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        contentWidth: rangee.width
        contentHeight: height
        clip: true
        interactive: contentWidth > width

        Row {
            id: rangee
            spacing: 8
            padding: 4
            x: 0   // 1.2: on the left, after the back arrow (like Menu 11)

            Repeater {
                model: puces.filtres
                delegate: Rectangle {
                    id: puce
                    readonly property bool active: modelData.cle === puces.actif
                    readonly property color accent: "#0055A4"   // 2.1: Fenestra royal blue, same everywhere in the theme
                    width: libelle.implicitWidth + Kirigami.Units.gridUnit * 2   // 1.2: Menu 11 capsule size
                    height: Kirigami.Units.gridUnit * 1.8
                    radius: height / 2
                    color: active ? accent
                         : (zone.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.25) : (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff"))
                    border.width: 1
                    border.color: active ? accent
                         : (zone.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.5) : (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000"))

                    Text {
                        id: libelle
                        anchors.centerIn: parent
                        text: modelData.nom
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize   // 1.2: like Menu 11
                        color: puce.active ? (Kirigami.Theme.textColor.hslLightness > 0.5 ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.backgroundColor) : Kirigami.Theme.textColor
                        font.bold: puce.active
                    }
                    MouseArea {
                        id: zone
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: puces.choisir(modelData.cle)
                    }
                }
            }
        }
    }
}
