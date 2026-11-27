/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // 2.1.1: updates through Discover (run once at start)
    Plasma5Support.DataSource {
        id: inscription
        engine: "executable"
        readonly property string commande: "python3 -I '" + String(Qt.resolvedUrl("../code/store_registry.py")).replace("file://", "") + "' add"
        onNewData: (source, donnees) => disconnectSource(source)
        Component.onCompleted: connectSource(commande)
    }

    // typed text (entered in the window, displayed in the capsule)
    property string texteRecherche: ""
    // search window open or not
    property bool fenetreOuverte: false

    // 2.0: magnifier mode, only a magnifier replaces the capsule in the panel
    readonly property bool modeLoupe: Plasmoid.configuration.modeLoupe === true

    // ── Capsule size ──
    // same calculation as the old capsule: from 70 px to 9 times the panel height,
    // in 12 steps (7 by default)
    readonly property int cran: Math.max(0, Math.min(12, Plasmoid.configuration.largeurCran))
    readonly property real largeurMin: 70
    readonly property real largeurMax: height * 9
    Layout.preferredWidth: modeLoupe ? Math.max(34, height) + 10 : largeurMin + (largeurMax - largeurMin) * cran / 12
    Layout.preferredHeight: 38
    Layout.minimumWidth: modeLoupe ? 34 : 50
    Layout.minimumHeight: 34

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // no tooltip on the search box, as on Windows 11
    toolTipMainText: ""
    toolTipSubText: ""
    preferredRepresentation: compactRepresentation

    compactRepresentation: Capsule {
        anchors.fill: parent
        ouverte: root.fenetreOuverte
        texte: root.texteRecherche
        modeLoupe: root.modeLoupe
        onBasculer: root.fenetreOuverte = !root.fenetreOuverte
        onOuvrir: root.fenetreOuverte = true
    }
    // empty full representation: Plasma expects one to display the capsule,
    // the search opens in its own window (FenetreRecherche)
    fullRepresentation: Item {}

    // no direct binding: the window can close by itself (click elsewhere)
    onFenetreOuverteChanged: {
        fenetre.visible = fenetreOuverte;
        if (!fenetreOuverte) texteRecherche = "";
    }

    // ── Placement: like the Start menu and Windows 11, 10 px above the panel,
    //    centered on the panel's screen, without leaving it ──
    function position(largeur, hauteur) {
        var dispo = root.availableScreenRect;
        var ecran = root.screenGeometry;
        var zone = Qt.rect(dispo.x + ecran.x, dispo.y + ecran.y, dispo.width, dispo.height);
        var ecart = 10;
        var x = zone.x + (zone.width - largeur) / 2;
        if (x < zone.x + ecart) x = zone.x + ecart;
        if (x + largeur > zone.x + zone.width - ecart) x = zone.x + zone.width - largeur - ecart;
        var y = (Plasmoid.location === PlasmaCore.Types.TopEdge)
                ? zone.y + ecart
                : zone.y + zone.height - hauteur - ecart;
        return Qt.point(x, y);
    }
    function placer() {
        var p = position(fenetre.width, fenetre.height);
        fenetre.x = p.x;
        fenetre.y = p.y;
    }

    FenetreRecherche {
        id: fenetre
        racine: root
    }

    // "About" (1.1), opened from the home screen "…" menu
    function ouvrirAPropos() { aPropos.ouvrir(); }
    AProposFenetre {
        id: aPropos
        // closed: the search becomes normal again (closes when clicking elsewhere)
        onVisibleChanged: {
            if (visible) return;
            fenetre.hideOnWindowDeactivate = true;
            if (fenetre.visible) fenetre.activer();
        }
    }
}
