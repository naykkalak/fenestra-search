/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

// Taskbar capsule: it is NOT an input field.
// It shows the text typed in the window (invisible field), with a simulated cursor:
// no keyboard problem under Wayland at the start of a session.
Item {
    id: capsule

    property bool ouverte: false
    property bool modeLoupe: false   // 2.0: magnifier only
    property string texte: ""
    signal basculer()
    signal ouvrir()

    readonly property bool themeSombre: Kirigami.Theme.textColor.hslLightness > 0.5

    // ── "Ear" SHARED with the Start menu (Fenestra Menu 11) ──
    // A single passive handle placed on the panel root (objectName
    // fenestraOreilleBarre): each widget plugs into it. A click on the panel outside
    // the capsule -> window closed.
    property QtObject oreille: null

    function racineBarre() {
        var p = capsule;
        while (p.parent) p = p.parent;
        return p;
    }
    function remettreOreille() {
        if (!oreille) return;
        oreille.enabled = false;
        oreille.enabled = true;
    }
    function oreillePartagee(haut) {
        var nom = "fenestraOreilleBarre";
        for (var i = 0; i < haut.data.length; i++) {
            var o = haut.data[i];
            if (o && o.objectName === nom) return o;
        }
        return Qt.createQmlObject(
            "import QtQuick\nPointHandler { objectName: \"fenestraOreilleBarre\"; acceptedButtons: Qt.LeftButton | Qt.RightButton }",
            haut, nom);
    }
    function poserOreille() {
        var haut = racineBarre();
        if (!haut || haut === capsule) return;
        if (oreille && oreille.parent === haut) return;
        oreille = oreillePartagee(haut);
        oreille.activeChanged.connect(function() {
            if (!oreille || !oreille.active) return;
            Qt.callLater(capsule.remettreOreille);
            if (!capsule.ouverte) return;
            var s = oreille.point.scenePosition;
            var l = capsule.mapFromItem(null, s.x, s.y);
            if (l.x >= 0 && l.y >= 0 && l.x < capsule.width && l.y < capsule.height) return;
            capsule.basculer();
        });
    }
    onOuverteChanged: {
        if (ouverte) {
            poserOreille();
            remettreOreille();
        }
    }
    Component.onDestruction: oreille = null   // shared: it is not destroyed

    Rectangle {
        id: fond
        visible: !capsule.modeLoupe
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 0.5
        height: parent.height - 1
        radius: height / 2
        color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g,
                       Kirigami.Theme.backgroundColor.b, 0.95)
        border.width: 1
        border.color: capsule.ouverte ? Kirigami.Theme.highlightColor
                      : (capsule.themeSombre ? Qt.rgba(1, 1, 1, 0.18) : Qt.rgba(0, 0, 0, 0.18))

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Kirigami.Icon {
                Layout.preferredWidth: fond.height * 0.65
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
                readonly property bool vide: capsule.texte === ""

                Text {
                    id: libelle
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -1
                    // a text that is too long scrolls to the left: the end stays visible
                    x: Math.min(0, parent.width - curseur.width - 1 - contentWidth)
                    text: affichage.vide ? i18n("Search") : capsule.texte
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
                    visible: capsule.ouverte && clignote.allume
                }
                Timer {
                    id: clignote
                    property bool allume: true
                    interval: 530
                    repeat: true
                    running: capsule.ouverte
                    onRunningChanged: allume = true
                    onTriggered: allume = !allume
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            onClicked: capsule.ouverte ? capsule.basculer() : capsule.ouvrir()
        }
    }

    // 2.0: magnifier mode, taskbar button (hover like the other buttons)
    Item {
        id: boutonLoupe
        visible: capsule.modeLoupe
        anchors.fill: parent
        Rectangle {   // 2.0: Start button frame (Menu 11)
            anchors.fill: parent
            anchors.leftMargin: -2   // 2.0: 48 px frame, 4 px gap, like the panel buttons
            anchors.rightMargin: -2
            anchors.topMargin: -4
            anchors.bottomMargin: -4
            radius: 5
            color: capsule.themeSombre ? "#26ffffff" : "#80ffffff"
            border.width: 1
            border.color: capsule.themeSombre ? "#1affffff" : "#14000000"
            opacity: (survolLoupe.containsMouse || capsule.ouverte) ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 100 } }
        }
        Image {   // 2.0: magnifier from "About", flipped (handle at the bottom right, like the other search boxes)
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.width, parent.height) * 0.95)
            height: width
            source: Qt.resolvedUrl("../images/preferences-system-search.svg")
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            mirror: true
            smooth: true
        }
        MouseArea {
            id: survolLoupe
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: capsule.ouverte ? capsule.basculer() : capsule.ouvrir()
        }
    }
}
