# linux-backup
Sauvegarde WEB et CONFIG d'un serveur linux

Informations :
	Script créer par Chucky2401
	Version de ce script 2.0.9
	Ce script est encore en phase d'écriture, merci de faire attention à ce que vous faites avec celui-ci.
	Je ne pourrais pas être tenu responsable pour les dégâts engendrer sur vos machines.

========================================================================================================================

Reprise du help du programme :
	sauvegarde.sh permet la sauvegarde des base de données MySQL, des fichiers des sites web et de la configuration pour le web.

		Version : 2.0.9  du 14/03/2016

		Utilisation : ./sauvegarde.sh [paramètre1]

		[-manu   | manu]         Mode manuelle, aucun log tout est affiché à l'écran
		[-autoc  | autoc]        Mode automatique avec un log complet (contient les erreurs)
		[-debug  | debug]        N'affiche que les variables à l'écran, ne réalise pas de backup
		[-help   | help]         Affiche ce message à l'écran
		[-readme | readme]       Affiche le readme

		Compression utilisée :

		Tous les fichiers (Configuration et Web) sont compressés en bzip2 en utilisant l'utilitaire tar.
		Les dumps (.sql) sont aussi compressés en bzip2 en utilisant l'utilitaire bzip2 (sans tar).


		Pour une configuration de ce script, merci de se reporter au readme
		Pour lire le readme utiliser le paramètre : readme ou -readme

========================================================================================================================

Changelog :

v.1

- Création initiale du script

v.2

- Suppression du fichier .err (errors). Fusion des erreurs dans le fichier .log
- Suppression séparation en trop lors de l'affichage de la fin de sauvegarde (-manu)
- Utilisation de variable pour la mise en forme
- Ajout couleurs HTML ; topHtml (en-tête) ; footHtml (fermeture balise body et html) ; Utilisation HTML pour log

v2.0.1

- Ajout de Shinken et du SNMP pour les fichiers de conf
- Ajout de la BDD mysql
- Modification mise en forme Debug
- Ajout de future modification au Help
- Valeur défaut du Switch appel le programme avec le paramètre -help

v2.0.2

- Ajout variable dbbnam pour le nom de la base de données
- Utilisation --events pour sauvegarde base mysql (ajout dans la variable directement)

v2.0.3

- Modification formatage temps d'éxecution (utilisation printf)
- Correction saut de ligne en trop pour Switch et If (entre chaque condition)
- Suppression texte : "Suppression des sauvegardes :"
- Ajout saut de ligne avec le temps écoulé (manuel seulement)

v2.0.4

- Déplacement du changelog et des informations dans un fichier `readme.txt`
- Suppression condition pour suppression et FTP, déplacement dans le Switch
- Remplacement echo par printf dans le help pour les titres

v2.0.5

- Fusion des deux fonctions tpsexe et tpsexeauto
- Utilisation d'une fonction pour la sauvegarde des BDDs
- Suppression variable htmlFinWoSaut, '$htmlFin' remplacer par '$htmlFin <br />', et '$htmlFinWoSaut' remplacer par '$htmlFin'
- Ajout d'une variable VERSION (afficher seulement dans debugage)
- Utilisation variable BDDNAM dans debug

v2.0.6

- Création fonction printMsg() pour afficher message ou logger en fonction du mode de lancement du programme (automatique ou manuel)
- Utilisation de printMsg() dans tpsexe et SaveBdd()
- Compression de SaveBdd(), utilisation que d'une boucle for
- Déplacement des variables utilisé dans les fonctions en début du script (logique de déclaration)
- Suppression de commentaires supperflues
- Améliorations message suppression
- Vidage de l'écran seulement si exécution manuelle
- Utilisation de printMsg dans Debug ; Ajout de la condition au début
- Suppression du message de fin de Debug
- Variable pour timestamp en une seule au lieu de deux.
- Création variable TAB pour ajout d'une tabulation dans SQL OK/NOK pour alignement correcte.
  - Au total envrion 70 lignes de codes en moins

v2.0.7

- Ajout variable exclusions pour sauvegarde fichiers Web
- Ajout durée sauvegarde fichiers Conf/Web

v2.0.8 - 30/10/2015

- Suppression de la partie "Création des archives" dans le help
- Ajout de la compression utilisé dans la partie du même nom dans le help
- Ajout du paramètre 'readme' pour afficher ce dernier
- Suppression du calcul de temps dans la fonction SaveBdd()
  - 10 lignes de codes en moins
    - Utilisation d'un fichier de paramètres (sauvegardeV2.ini)
      - Déplacement de 6 variables dans ce fichier et ajout d'un underscore devant chaque variables
        - _VERSION
        - _DERNIERE_MODIF
        - _BACKDIR
        - _LOG
        - _TEST
        - _PASS_MYSQL
    - Suppression de toutes les lignes commentées
    - Suppression du case 'test'
    - Modification variable _BACKDIR par _PATH_SAUVEGARDE
    - Ajout variables
      - _PATH_LOG=$_PATH_SAUVEGARDE/log
      - _PATH_SCRIPT=/root/scripts
      - _PATH_MODELE=$_PATH_SCRIPT/MODELE
    - Mis en commentaire de la création du fichier Modèle du texte dans le mail (var txtMail) (Lignes 171 à 173)
    - Correction bug affichage échec lors de la sauvegarde des fichiers web
      - Inversement de la condition
    - Ajout variable d'exclusion pour les répertoires de Configuration
      - Sera utile pour la création des Fonctions
    - Déplacer toutes les variables MYSQL dans fichier paramètres
      - Inclus renommage de toutes les variables
    - Variables dans debug trié correctement
    - Suppression complète du calcul de temps
      - Pour répertoire Web et Configuration dans le manuel
    - Création de deux Fonctions
      - Fonctions pour sauvegarder dossier de configuration
      - Fonction pour sauvegarder les dossier web

v2.0.9

- Remplacement de la variable $htmlSaut par la bonne : $formSautHtml
- Correction variable pour de mise en forme en ajoutant 'form'
