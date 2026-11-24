/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.components as PlasmaComponents
import org.kde.ksvg as KSvg   // Fenestra: scroll bar
import "Classement.js" as Classement

// List of results, grouped by section
PlasmaComponents.ScrollView {
    id: liste

    property var resultats: []
    property bool enCours: false      // search started, results not yet arrived
    property string texte: ""
    property int courant: 0
    // selected result (keyboard or mouse): shown in the right pane (1.1)
    readonly property var selection: (courant >= 0 && courant < resultats.length) ? resultats[courant] : null

    signal lancer(var resultat)

    // 1.2: collapsed sections (key = section name); their rows are hidden, the header stays
    property var repliees: ({})
    function estReplie(i) { return i >= 0 && i < resultats.length && repliees[resultats[i].rubrique] === true; }
    function basculer(rubrique) {
        var c = {};
        for (var k in repliees) c[k] = repliees[k];
        c[rubrique] = !c[rubrique];
        repliees = c;
        if (estReplie(courant)) {   // the selection does not stay on a hidden row
            var j = courant;
            while (j < resultats.length && estReplie(j)) j++;
            if (j >= resultats.length) {
                j = courant;
                while (j >= 0 && estReplie(j)) j--;
            }
            courant = j;
        }
    }
    onTexteChanged: if (texte.length === 0) repliees = ({})

    onResultatsChanged: {
        courant = 0;
        while (courant < resultats.length && estReplie(courant)) courant++;
        if (courant >= resultats.length) courant = (resultats.length > 0) ? -1 : 0;
    }

    function monter() {
        var j = courant - 1;
        while (j >= 0 && estReplie(j)) j--;
        if (j >= 0) courant = j;
    }
    function descendre() {
        var j = courant + 1;
        while (j < resultats.length && estReplie(j)) j++;
        if (j < resultats.length) courant = j;
    }
    function lancerCourant() {
        if (courant < 0 || courant >= resultats.length) return false;
        lancer(resultats[courant]);
        return true;
    }

    clip: true
    PlasmaComponents.ScrollBar.vertical: PlasmaComponents.ScrollBar {   // Fenestra: Windows 11-style bar
        id: barreFenestra
        parent: liste   // placement in the ScrollView
        x: liste.mirrored ? 0 : liste.width - width
        y: liste.topPadding
        height: liste.availableHeight
        implicitWidth: 14   // original width of the theme's bar
        hoverEnabled: true
        visible: size < 1.0 && policy !== PlasmaComponents.ScrollBar.AlwaysOff
        readonly property bool survol: hovered || pressed
        readonly property bool eveille: active || extinction.running
        function reveil() { extinction.restart(); }   // called when the mouse moves
        Timer { id: extinction; interval: 1500 }
        background: KSvg.FrameSvgItem {   // hover: theme background
            imagePath: "widgets/scrollbar"
            prefix: "background-vertical"
            transform: Translate { x: 4 }   // stuck to the edge, like Windows
            opacity: barreFenestra.survol ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
        contentItem: Item {
            implicitWidth: 14
            Rectangle {   // mouse moving: thin line on the edge side
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 3
                anchors.bottomMargin: 3
                width: 2
                radius: 1
                color: Kirigami.Theme.textColor
                opacity: (barreFenestra.eveille && !barreFenestra.survol) ? 0.55 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
            KSvg.FrameSvgItem {   // hover / drag: theme handle
                anchors.fill: parent
                imagePath: "widgets/scrollbar"
                prefix: "mouseover-slider"
                transform: Translate { x: 4 }   // stuck to the edge, like Windows
                opacity: barreFenestra.survol ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    ListView {
        id: vue
        width: parent.width
        height: parent.height
        model: liste.resultats
        spacing: 0   // 1.2: the 4 px gap is in the row height
        currentIndex: liste.courant
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 0      // no trailing when the mouse moves the selection
        highlightResizeDuration: 0
        HoverHandler { onPointChanged: barreFenestra.reveil() }   // Fenestra: wakes up the bar
        section.property: "rubrique"

        // nothing found (or search in progress)
        Column {
            anchors.centerIn: parent
            spacing: 10
            visible: liste.resultats.length === 0 && liste.texte.length > 0

            PlasmaComponents.BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                running: liste.enCours
                visible: liste.enCours
            }
            Text {
                text: liste.enCours ? i18n("Searching…") : i18n("No results found")
                color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.5)
                font.family: Kirigami.Theme.defaultFont.family
                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
            }
        }

        highlight: Item {   // 1.2: without the 4 px gap under the row
            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: 4
                color: (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff")   // 2.1: same as the home screen hover
                radius: 4
            }
        }

        section.delegate: Item {   // 1.2: collapsible section header, drawn like Menu 11
            id: rubrique
            width: vue.width
            readonly property bool replie: liste.repliees[section] === true
            height: entete.height + (replie ? 0 : Kirigami.Units.smallSpacing)

            Item {
                id: entete
                width: parent.width
                height: titre.implicitHeight + Kirigami.Units.smallSpacing * 3

                Rectangle {   // colored bar on the left
                    id: trait
                    anchors.left: parent.left
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.verticalCenter: titre.verticalCenter
                    width: 3
                    height: titre.implicitHeight * 0.85
                    radius: 2
                    color: "#0055A4"   // 2.1: royal blue, whatever the accent color
                    opacity: 1
                }
                Text {
                    id: titre
                    anchors.left: trait.right
                    anchors.leftMargin: Kirigami.Units.smallSpacing * 2
                    anchors.top: parent.top
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.right: fleche.left
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    text: section
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.88
                    font.weight: Font.DemiBold
                    color: Kirigami.Theme.textColor
                    opacity: 0.75
                    elide: Text.ElideRight
                }
                Kirigami.Icon {   // arrow to collapse the section
                    id: fleche
                    anchors.right: parent.right
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    anchors.verticalCenter: titre.verticalCenter
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: rubrique.replie ? "arrow-right" : "arrow-down"
                    opacity: souriEntete.containsMouse ? 0.9 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 100 } }
                }
                Rectangle {   // separator line
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.smallSpacing
                    anchors.bottom: parent.bottom
                    height: 1
                    color: Kirigami.Theme.textColor
                    opacity: 0.08
                }
                MouseArea {
                    id: souriEntete
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: liste.basculer(section)
                }
            }
        }

        delegate: Item {
            id: ligne
            width: vue.width
            readonly property bool cachee: liste.repliees[modelData.rubrique] === true   // 1.2: collapsed section
            height: cachee ? 0 : contenu.implicitHeight + 12 + 4
            visible: !cachee
            readonly property bool choisie: vue.currentIndex === index

            Rectangle {
                anchors.fill: parent
                anchors.bottomMargin: 4
                color: (survol.containsMouse && !ligne.choisie) ? (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#26ffffff" : "#80ffffff") : "transparent"   // 2.1: the selected row is already drawn by the highlight
                radius: 4
                border.width: ligne.choisie ? 1 : 0
                border.color: (survol.containsMouse || ligne.choisie) ? (Kirigami.Theme.textColor.hslLightness > 0.5 ? "#1affffff" : "#14000000") : "transparent"

                RowLayout {
                    id: contenu
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    spacing: 12

                    Kirigami.Icon {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: modelData.decoration
                        color: Kirigami.Theme.textColor
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: modelData.display || ""
                            color: Kirigami.Theme.textColor
                            font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: Classement.cheminCourt(modelData)
                            color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.6)
                            font.family: Kirigami.Theme.smallFont.family
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            MouseArea {
                id: survol
                anchors.fill: parent
                anchors.bottomMargin: 4
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: liste.courant = index      // the mouse takes the selection
                onClicked: liste.lancer(modelData)
            }
        }
    }
}
