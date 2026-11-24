/*
 * Fenestra Search — https://github.com/naykkalak/fenestra-search
 * SPDX-FileCopyrightText: 2026 naykkalak
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami
import org.kde.milou as Milou
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.private.kicker 0.1 as Kicker
import "Classement.js" as Classement
import "Moteurs.js" as Moteurs

// Search window: ITS OWN window (PlasmaCore.Dialog), like the Start menu.
// A panel widget's standard window does not get the keyboard at the start of a session
// under Wayland; a Dialog does.
PlasmaCore.Dialog {
    id: fenetre

    property var racine: null
    readonly property string texte: racine ? racine.texteRecherche : ""
    property string filtre: "All"

    // 2.1: total window size (frame included); the content area is this minus the frame margins
    // 2.1: the window width follows Fenestra Menu 11: its "Menu size" setting is read by
    // code/taille-menu11.sh (0 = automatic, 1 = small, 2 = large)
    property int tailleMenu: 0
    readonly property int colonnesMenu: {
        if (tailleMenu === 1) return 6;
        if (tailleMenu === 2) return 8;
        var w = racine ? racine.screenGeometry.width : 1920;   // automatic: same rule as Menu 11
        return w >= 2500 ? 8 : (w >= 1900 ? 7 : 6);
    }
    // Menu 11 content width: 697 px for 7 columns, otherwise 96 px per column, + 2 x 8 px of side margin
    readonly property int largeurContenu: (colonnesMenu === 7 ? 697 : 96 * colonnesMenu) + 16
    readonly property int largeurListe: 310    // results list: fixed width, the right pane takes the rest
    readonly property int largeurTotale: largeurContenu + margins.left + margins.right
    onWidthChanged: if (visible && racine) racine.placer()   // the size changes: centered again
    // 2.1: same height as the Menu 11 window (820 px), never taller than the free height
    // of the screen (same rule as Menu 11: small screens, 125 % scaling)
    readonly property int hauteurTotale: Math.min(820, Math.max(Kirigami.Units.gridUnit * 20,
        (racine ? racine.availableScreenRect.height : 1080) - Math.round(Kirigami.Units.gridUnit * 1.85)))
    width: largeurTotale
    height: hauteurTotale
    // 2.1: four rounded corners: a window placed at the bottom = a "floating" window
    // (its position is computed by placer() in main.qml)
    location: Plasmoid.location === PlasmaCore.Types.BottomEdge ? PlasmaCore.Types.Floating : Plasmoid.location
    flags: Qt.WindowStaysOnTopHint
    hideOnWindowDeactivate: true
    visible: false

    property int ouvertures: 0         // counts the openings: the home screen is read again

    function activer() {
        fenetre.requestActivate();
        saisie.forceActiveFocus();
    }

    function fermer() {
        racine.fenetreOuverte = false;
    }

    onVisibleChanged: {
        if (visible) {
            ouvertures++;
            activer();
            racine.placer();
            Qt.callLater(racine.placer);      // once the real size is known
            Qt.callLater(activer);            // a second time, window really shown
        } else {
            saisie.text = "";
            filtre = "All";
            roueReglages.fermerMenu();   // 2.1: the menus do not stay open for the next opening
            bandeau.fermerMenu();
            if (racine.fenetreOuverte) racine.fenetreOuverte = false;   // closed by itself
        }
    }

    // ── Engine: KRunner (via Milou) ──
    property string requete: ""        // sent to KRunner 60 ms after the last key
    property var resultats: []         // ranked and grouped (Classement.js)
    property bool enCours: false
    property var carteResultat: null   // top card: calculation or first document
    property bool carteCalcul: false

    // ── Web search: last line of the list ──
    property string sortieKde: ""      // engine chosen in KDE (read by code/moteur-kde.sh)
    readonly property var moteur: {
        var choix = Plasmoid.configuration.moteurWeb;
        return (choix && choix !== "kde" && Moteurs.trouver(choix)) || Moteurs.depuisKde(sortieKde);
    }

    onTexteChanged: relancer()
    onFiltreChanged: relancer()

    function relancer() {
        enCours = texte.length > 0;
        if (texte.length > 0) {
            finAttente.restart();
            attenteFrappe.restart();
        } else {
            attenteFrappe.stop();
            finAttente.stop();
            requete = "";
            resultats = [];
            carteResultat = null;
        }
    }

    function reclasser() {
        if (texte.length === 0) { resultats = []; return; }
        var bruts = [];
        for (var i = 0; i < copie.count; i++) {
            var o = copie.objectAt(i);
            if (!o) continue;
            var url = (o.url || "").toString();
            if (Classement.estLogitheque(o.category, url)) continue;   // no "to get" apps
            var icone = (o.decoration || "").toString();
            if (icone === "" || icone === "QIcon()")
                icone = /^https?:\/\//.test(url) ? "internet-web-browser" : "application-x-executable";
            bruts.push({
                display: (o.display || "").toString(),
                decoration: icone,
                category: (o.category || "Other").toString(),
                url: url,
                subtext: (o.subtext || "").toString(),
                duplicateId: (o.duplicateId || "").toString(),
                index: o.rang
            });
        }
        var liste = Classement.classer(bruts, texte, filtre, filtre === "All" ? 20 : 120,
                                       i18n("Other Results"));
        if (liste.length > 0) liste[0].rubrique = i18n("Best match");   // 1.1: like Windows 11

        // top card: the calculation if KRunner offers one first, otherwise the first result
        var calc = bruts.length > 0 && Classement.estCalcul(bruts[0].category, bruts[0].decoration, bruts[0].duplicateId);
        carteCalcul = calc;
        carteResultat = calc ? bruts[0] : (liste.length > 0 ? liste[0] : null);

        if (filtre === "All" || filtre === "Web") {
            liste.push({
                web: true,
                display: i18n("Search “%1” on %2", texte, moteur.nom),
                decoration: "internet-web-browser",
                category: "Web",
                url: Moteurs.adresse(moteur, texte),
                subtext: Moteurs.domaine(moteur),
                duplicateId: "",
                rubrique: i18n("Web search")
            });
        }
        resultats = liste;
        if (requete === texte) {
            enCours = false;
            finAttente.stop();
        }
    }

    // opens a result then closes the window
    function lancer(r) {
        if (!r) return;
        var url = r.url || "";
        if (r.web) {
            Qt.openUrlExternally(url);
        } else if (Classement.estApplication(r.category, url, r.duplicateId, r.decoration)) {
            modele.run(modele.index(r.index, 0));
        } else if (url.length > 0 && url.indexOf("http") !== 0) {
            Qt.openUrlExternally(url);        // file or folder: opened directly
        } else {
            modele.run(modele.index(r.index, 0));
        }
        fermer();
    }

    mainItem: Item {
        width: fenetre.largeurTotale - fenetre.margins.left - fenetre.margins.right
        height: fenetre.hauteurTotale - fenetre.margins.top - fenetre.margins.bottom

        // non-visual objects here: a Dialog only accepts graphical items
        Milou.ResultsModel {
            id: modele
            queryString: fenetre.requete
            limit: fenetre.filtre === "All" ? 20 : 120
        }

        Timer {   // wait for the end of typing before querying KRunner
            id: attenteFrappe
            interval: 60
            onTriggered: {
                fenetre.requete = fenetre.texte;
                fenetre.reclasser();
            }
        }
        Timer {   // results arrive in waves: the updates are batched
            id: attenteResultats
            interval: 24
            onTriggered: fenetre.reclasser()
        }
        Timer {   // "Searching…" does not stay displayed forever
            id: finAttente
            interval: 900
            onTriggered: fenetre.enCours = false
        }

        // KDE web engine (System Settings > Web Search), read once at opening
        Plasma5Support.DataSource {
            id: lectureKde
            engine: "executable"
            readonly property string commande: "sh '" + String(Qt.resolvedUrl("../code/moteur-kde.sh")).replace("file://", "") + "'"
            onNewData: (source, donnees) => {
                fenetre.sortieKde = String(donnees["stdout"] || "");
                disconnectSource(source);
            }
        }
        // 2.1: "Menu size" setting of Fenestra Menu 11, read at start and at each opening
        Plasma5Support.DataSource {
            id: lectureTaille
            engine: "executable"
            readonly property string commande: "sh '" + String(Qt.resolvedUrl("../code/taille-menu11.sh")).replace("file://", "") + "'"
            onNewData: (source, donnees) => {
                var m = /Taille=(\d)/.exec(String(donnees["stdout"] || ""));
                fenetre.tailleMenu = m ? parseInt(m[1]) : 0;
                disconnectSource(source);
            }
            Component.onCompleted: connectSource(commande)
        }
        Connections {
            target: fenetre
            function onVisibleChanged() {
                if (!fenetre.visible) return;
                lectureTaille.connectSource(lectureTaille.commande);
                if (Plasmoid.configuration.moteurWeb === "kde")
                    lectureKde.connectSource(lectureKde.commande);
            }
        }

        // home: same source as the Start menu (Kicker), recent items only
        Kicker.RootModel {
            id: modeleRecents
            autoPopulate: false
            appNameFormat: 0
            flat: true
            sorted: true
            showAllAppsCategorized: false
            showSeparators: false
            appletInterface: fenetre.racine
            showAllApps: false
            showRecentApps: true
            showRecentDocs: true
            showPowerSession: false
            Component.onCompleted: refresh()
        }

        // opening a System Settings module
        Plasma5Support.DataSource {
            id: commande
            engine: "executable"
            onNewData: (source, donnees) => disconnectSource(source)
        }

        // copy of the model results, readable in JavaScript
        Instantiator {
            id: copie
            model: modele
            delegate: QtObject {
                property int rang: index
                property var category: model.category !== undefined ? model.category
                                     : (model.matchCategory !== undefined ? model.matchCategory : "")
                property var display: model.display || ""
                property var decoration: model.decoration || ""
                property var url: model.url || ""
                property var subtext: model.subtext || ""
                property var duplicateId: model.duplicateId || ""
            }
            onCountChanged: attenteResultats.restart()
        }
        Connections {
            target: modele
            function onRowsInserted() { attenteResultats.restart(); }
            function onRowsRemoved() { attenteResultats.restart(); }
            function onModelReset() { attenteResultats.restart(); }
            function onDataChanged() { attenteResultats.restart(); }
        }

        Item {
            id: cadre
            // Fenestra: exactly the inner area of the window (size minus the frame),
            // for identical margins on the left, right and bottom
            width: fenetre.width - fenetre.margins.left - fenetre.margins.right
            height: fenetre.height - fenetre.margins.top - fenetre.margins.bottom

            // invisible field: it receives the typing; the capsule displays it
            PlasmaComponents.TextField {
                id: saisie
                width: 1
                height: 1
                opacity: 0
                onTextChanged: racine.texteRecherche = text
                onAccepted: listeResultats.lancerCourant()
                Keys.onEscapePressed: fenetre.fermer()
                Keys.onUpPressed: listeResultats.monter()
                Keys.onDownPressed: listeResultats.descendre()
                Keys.onTabPressed: (event) => { event.accepted = true; }
            }

            // ── Filter chips (visible during a search) ──
            Item {
                id: zonePuces
                readonly property bool montree: fenetre.texte.length > 0
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                anchors.topMargin: montree ? 10 : 0
                height: montree ? Math.ceil(Kirigami.Units.gridUnit * 1.8) + 8 : 0   // 1.2: Menu 11 capsules
                opacity: montree ? 1 : 0
                clip: true
                visible: height > 0 || opacity > 0
                Behavior on height { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                Behavior on anchors.topMargin { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration; easing.type: Easing.OutCubic } }

                PucesFiltres {
                    anchors.fill: parent
                    actif: fenetre.filtre
                    onChoisir: (f) => fenetre.filtre = f
                    onRetour: {   // 1.2: back arrow, returns to the home screen
                        saisie.text = "";
                        Qt.callLater(fenetre.activer);
                    }
                }
            }

            // ── Top card: calculation or preview of the first document ──
            CarteHaut {
                id: carteHaut
                anchors.top: zonePuces.bottom
                anchors.topMargin: 8
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                texte: fenetre.texte
                resultat: fenetre.carteResultat
                calcul: fenetre.carteCalcul
                onLancer: (r) => fenetre.lancer(r)
            }

            // ── Results ──
            ListeResultats {
                id: listeResultats
                anchors.top: carteHaut.bottom
                anchors.topMargin: 6
                anchors.left: parent.left
                anchors.right: volet.visible ? volet.left : parent.right
                anchors.bottom: bandeau.top
                anchors.leftMargin: 8   // 2.1: section bar 18 px from the window edge, like the right pane
                anchors.rightMargin: volet.visible ? 8 : 12   // 2.1: scrollbar 8 px from the right pane
                anchors.bottomMargin: 12
                visible: fenetre.texte.length > 0
                resultats: fenetre.resultats
                enCours: fenetre.enCours
                texte: fenetre.texte
                onLancer: (r) => fenetre.lancer(r)
            }

            // ── Right pane (1.1): the selected result, its actions, its recent items ──
            VoletDetails {
                id: volet
                anchors.top: carteHaut.bottom
                anchors.topMargin: 6
                anchors.right: parent.right
                anchors.bottom: bandeau.top
                anchors.rightMargin: 12
                anchors.bottomMargin: 12
                width: cadre.width - fenetre.largeurListe - 36   // 2.1: the list keeps its width, the pane takes the rest
                visible: fenetre.texte.length > 0 && listeResultats.selection !== null
                resultat: visible ? listeResultats.selection : null
                onLancer: (r) => fenetre.lancer(r)
                onFini: fenetre.fermer()
                onEmplacement: (r) => {
                    var fait = r && r.index !== undefined && modele.runAction(modele.index(r.index, 0), 0);
                    if (fait) fenetre.fermer();
                    else volet.montrerEmplacement();
                }
            }

            // ── Home (nothing typed) ──
            Accueil {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: bandeau.top
                anchors.leftMargin: 22
                anchors.rightMargin: 12   // 2.1: home content 18 px from the window edge on the right, like the results
                anchors.topMargin: 26   // 2.0: 10 px more, below the gear
                anchors.bottomMargin: 12
                visible: fenetre.texte.length === 0
                modeleApps: modeleRecents.count > 0 ? modeleRecents.modelForRow(0) : null
                modeleDocs: modeleRecents.count > 1 ? modeleRecents.modelForRow(1) : null
                revision: fenetre.ouvertures
                onFini: fenetre.fermer()
                onOuvrirModule: (module) => {
                    // module .desktop file, otherwise System Settings directly
                    commande.connectSource("kioclient exec /usr/share/applications/" + module + ".desktop || systemsettings " + module);
                    fenetre.fermer();
                }
            }

            // ── Gear (1.2): same place on the home screen and in the results ──
            BoutonReglages {
                id: roueReglages
                anchors.top: parent.top
                anchors.topMargin: 10 + (Math.ceil(Kirigami.Units.gridUnit * 1.8) + 8 - height) / 2
                anchors.right: parent.right
                anchors.rightMargin: 12
                onOuvrirModule: (module) => {
                    // module .desktop file, otherwise System Settings directly
                    commande.connectSource("kioclient exec /usr/share/applications/" + module + ".desktop || systemsettings " + module);
                    fenetre.fermer();
                }
                onConfigurer: {
                    fenetre.fermer();
                    Plasmoid.internalAction("configure").trigger();
                }
            }

            // ── Bottom strip ──
            BandeauBas {
                id: bandeau
                // 2.1: inside the frame, like the Menu 11 footer (the four corners are rounded)
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                loupe: racine.modeLoupe === true
                texte: fenetre.texte
                actif: fenetre.visible
                margeGauche: fenetre.margins.left
                margeDroite: fenetre.margins.right
                margeBas: fenetre.margins.bottom
                onFocaliser: Qt.callLater(fenetre.activer)
                onAPropos: {
                    // the search stays open behind "About" (given back when it closes)
                    fenetre.hideOnWindowDeactivate = false;
                    racine.ouvrirAPropos();
                }
            }
        }
    }
}
