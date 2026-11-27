/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras   // 2.1: footer strip, same component as Menu 11
import org.kde.plasma.components as PC3

// Bottom strip, like the Start menu footer.
// 1.2: the "Back" button is now the arrow to the left of the capsules.
Rectangle {
    id: bandeau

    signal aPropos()   // 1.2: "About" is in the strip's "···" menu
    signal focaliser()   // 2.0: gives the keyboard back to the window

    // 2.1: closes the "···" menu (called when the search window closes)
    function fermerMenu() { menuPlus.close(); }
    property bool loupe: false    // 2.0: magnifier mode, the typing area is in the strip
    property string texte: ""
    property bool actif: false
    // 2.1: frame margins of the window: the strip's background extends to the window edges
    property real margeGauche: 0
    property real margeDroite: 0
    property real margeBas: 0

    height: Kirigami.Units.gridUnit * 3 - 4   // same height as the Menu 11 footer (which is 10 px lower since its 2.1)
    color: "transparent"   // Fenestra: theme background, like the Menu 11 footer

    PlasmaExtras.PlasmoidHeading {   // 2.1: same footer strip as Menu 11 (rounded bottom corners)
        anchors.fill: parent
        position: PC3.ToolBar.Footer
        leftInset: -bandeau.margeGauche
        rightInset: -bandeau.margeDroite
        bottomInset: -bandeau.margeBas
    }

    Rectangle {   // separator line
        visible: false   // Fenestra: the theme background already has its line
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000")
    }

    // 2.0: magnifier mode, the typing area is here (like the panel capsule)
    FontMetrics { id: mesure; font: Kirigami.Theme.defaultFont }

    Rectangle {
        id: champ
        visible: bandeau.loupe
        anchors.left: parent.left
        anchors.leftMargin: Kirigami.Units.gridUnit
        anchors.right: boutonPlus.left
        anchors.rightMargin: Kirigami.Units.gridUnit
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: bandeau.margeBas / 2 + 1   // centred in the visible strip (its background extends below by the frame margin)
        height: Math.ceil(mesure.height) + 20   // 2.0: like the Menu 11 search area (font + 2 x 10 px)
        radius: height / 2
        color: Kirigami.Theme.backgroundColor   // 2.0: same background as the Menu 11 search
        border.width: 1
        border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                              Kirigami.Theme.textColor.b, 0.05)   // 2.0: same thin border as Menu 11

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Kirigami.Icon {
                Layout.preferredWidth: champ.height * 0.65
                Layout.preferredHeight: Layout.preferredWidth
                Layout.alignment: Qt.AlignVCenter
                source: Qt.resolvedUrl("../images/loupe.svg")
            }

            // input-field-like display: typed text + blinking cursor
            Item {
                id: affichage
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                readonly property bool vide: bandeau.texte === ""

                Text {
                    id: libelle
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.min(0, parent.width - curseur.width - 1 - contentWidth)
                    text: affichage.vide ? i18n("Type here to search") : bandeau.texte
                    color: affichage.vide
                           ? Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g,
                                     Kirigami.Theme.textColor.b, 0.55)
                           : Kirigami.Theme.textColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    font.family: Kirigami.Theme.defaultFont.family
                }
                Rectangle {   // cursor: at the start when empty, after the text otherwise
                    id: curseur
                    width: 1
                    height: Math.round(libelle.font.pixelSize * 1.2)
                    anchors.verticalCenter: parent.verticalCenter
                    x: affichage.vide ? 0 : Math.min(libelle.x + libelle.contentWidth + 1, parent.width - width)
                    color: Kirigami.Theme.textColor
                    visible: bandeau.actif && clignote.allume
                }
                Timer {
                    id: clignote
                    property bool allume: true
                    interval: 530
                    repeat: true
                    running: bandeau.loupe && bandeau.actif
                    onRunningChanged: allume = true
                    onTriggered: allume = !allume
                }
            }
        }
        MouseArea {   // a click gives the keyboard back to the window (the real field is invisible)
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: bandeau.focaliser()
        }
    }

    // "···" in the bottom strip: "About" (1.2: moved down from the home screen)
    Item {
        id: boutonPlus
        anchors.right: parent.right
        anchors.rightMargin: Kirigami.Units.gridUnit
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: bandeau.margeBas / 2 + 1   // centred in the visible strip (its background extends below by the frame margin)
        width: textePlus.implicitWidth + 18
        height: 26
        Rectangle {
            anchors.fill: parent
            radius: 5
            color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff")
            border.width: 1
            border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000")
            opacity: (survolPlus.hovered || menuPlus.opened) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        Text {
            id: textePlus
            anchors.centerIn: parent
            text: "···"
            color: Kirigami.Theme.textColor
            font.pointSize: Kirigami.Theme.defaultFont.pointSize
        }
        HoverHandler { id: survolPlus; cursorShape: Qt.PointingHandCursor }
        PC3.ToolTip.text: i18n("More options")
        PC3.ToolTip.visible: survolPlus.hovered && !menuPlus.opened
        PC3.ToolTip.delay: 400
        TapHandler { onTapped: menuPlus.opened ? menuPlus.close() : menuPlus.open() }
        onVisibleChanged: if (!visible) menuPlus.close()

        QQC2.Popup {
            id: menuPlus
            x: boutonPlus.width - width
            y: -height - 4   // opens upwards, the button is at the bottom
            closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutsideParent
            padding: 6
            background: Rectangle {
                radius: 8
                color: Kirigami.Theme.backgroundColor
                border.width: 1
                border.color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#30ffffff" : "#30000000")
            }
            contentItem: ColumnLayout {
                spacing: 0
                LigneMenu {
                    libelle: i18n("About Fenestra Search")
                    icone: "help-about"
                    onChoisie: { menuPlus.close(); bandeau.aPropos(); }
                }
            }
        }
    }

}
