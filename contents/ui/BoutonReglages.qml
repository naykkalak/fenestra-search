/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

// Gear at the top right (home and results), like the Menu 11 search:
// opens "Search settings" and "Configure Fenestra Search…"
Item {
    id: reglages

    signal ouvrirModule(string module)
    signal configurer()

    // 2.1: closes the menu (called when the search window closes: the button itself stays "visible")
    function fermerMenu() { menu.close(); }

    width: Math.ceil(Kirigami.Units.gridUnit * 2)
    height: width
    Accessible.role: Accessible.Button

    onVisibleChanged: if (!visible) menu.close()

    Rectangle {
        anchors.fill: parent
        radius: 5
        color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff")
        border.width: 1
        border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000")
        opacity: (reglagesSouris.containsMouse || menu.opened) ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 100 } }
    }
    Item {   // real Fluent gear (ic_fluent_settings_24_regular), tinted like the text
        id: roueReglages
        anchors.centerIn: parent
        width: Kirigami.Units.iconSizes.smallMedium
        height: width
        Image {
            id: roueForme
            anchors.fill: parent
            source: Qt.resolvedUrl("../icons/fluent/settings.svg")
            sourceSize.width: Math.max(1, roueReglages.width) * 2
            sourceSize.height: Math.max(1, roueReglages.height) * 2
            smooth: true
            visible: false
        }
        Rectangle {
            id: roueCouleur
            anchors.fill: parent
            color: Kirigami.Theme.textColor
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: roueCouleur
            maskEnabled: true
            maskSource: roueForme
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            opacity: 0.8   // 2.0: same dark gray as the KDE Connect icon (theme text at 80 %)
        }
    }
    MouseArea {
        id: reglagesSouris
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: menu.opened ? menu.close() : menu.open()
        PC3.ToolTip.text: i18n("Settings")
        PC3.ToolTip.visible: reglagesSouris.containsMouse && !menu.opened
        PC3.ToolTip.delay: 400
    }

    QQC2.Popup {
        id: menu
        x: reglages.width - width
        y: reglages.height + 4
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutsideParent
        padding: 6
        // solid background and thin frame, like the home tiles and chips
        background: Rectangle {
            radius: 8
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#30ffffff" : "#30000000")
        }
        contentItem: ColumnLayout {
            spacing: 0
            // Search section of System Settings, on the indexing page
            LigneMenu {
                libelle: i18n("Search settings")
                icone: "search"
                onChoisie: { menu.close(); reglages.ouvrirModule("kcm_baloofile"); }
            }
            LigneMenu {
                libelle: i18n("Configure Fenestra Search…")
                icone: "configure"
                onChoisie: { menu.close(); reglages.configurer(); }
            }
        }
    }
}
