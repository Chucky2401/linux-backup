#!/bin/bash
##

#set -xv
export TERM=xterm


## Initilisation des variables (main | fonction)

	# Couleurs en fonction du mode (auto | manu)
		if [[ $1 = "-manu" ]] || [[ $1 = "manu" ]] || [[ $1 = "debug" ]] || [[ $1 = "-debug" ]]
		then
			formNormal="\033[0m"
			formSurligne="\033[4m"
			formGras="\033[1m"
			formRouge="\033[1;31m"
			formVert="\033[1;32m"
			formSaut="\n"
			formSautHtml=""
			formMargin=""
			formGrasSurligne="\033[4m\033[1m"
			TAB="	"
		else
			formNormal="</span>"
			formSurligne="<span style=\"text-decoration:underline;\">"
			formGras="<span style=\"font-weight:bold;\">"
			formRouge="<span style=\"color:red;margin:2em;\">"
			formVert="<span style=\"color:green;margin:2em;\">"
			formSaut="<br />"
			formSautHtml="<br />"
			formMargin="<span style=\"margin:1em;\">"
			formGrasSurligne="<span style=\"text-decoration:underline;font-weight:bold;\">"
			TAB="&emsp;&emsp;"
		fi

	# Général
		DATE=`date +'%d-%m-%Y'`
		DATEHEURE=`date +'%d-%m-%Y_%H:%M:%S'`
		_PATH_SCRIPT=/root/scripts
		# Ajout du fichier de paramètre
		. $_PATH_SCRIPT/sauvegardeV2.ini

	# Suppression des vieilles sauvegarde
		DELETE=Y
		DAYS=9
	# Sauvegarde par FTP
		FTP=N
		HOSTFTP=192.168.1.12
		USERFTP=debian
		PWDFTP=***********
	# Dossier et BDD à sauvegarder
		REPWWW=('/var/www/glpi' '/home/tristan/www');
		REPWWWNAM=('glpi' 'tristan');
		REPWWWEXC=('PASDEXCLUSION' '\[Archives\]')
	# Divers : $errors   => Nombre d'erreurs
	#		   $nbsupp   => Nombre de fichiers supprimés
	#		   $mail     => Envoie d'un mail à la fin de la sauvegarde (auto seulement) ?
	#		   $txtMail  => Texte qui sera affiché dans le mail
	#		   $topHtml	 => Début de la page HTML
	#		   $footHtml => Fin de la page HTML
		errors=0
		nbsupp=0
		envMail=Y
		txtMail=$_PATH_SCRIPT/MODELE/txtMail
		topHtml=$_PATH_SCRIPT/MODELE/top_html
		footHtml=$_PATH_SCRIPT/MODELE/foot_html

	if [[ $2 = "test" ]]
	then
		_PATH_SAUVEGARDE=/mnt/BackupWeb/TEST
	fi

## Fonctions

	# Affichage un message ou log en fonction du mode (auto | manu)
		printMsg(){
			if [ $1 == "-manu" ] || [ $1 == "manu" ] || [ $1 == "debug" ] || [ $1 == "-debug" ]
			then
				shift
				echo -e $*
			else
				shift
				echo -e $* >> $_LOG
			fi
		}

	# Calcul durée script
		tpsexe(){
			heu=0
			min=0
			sec=0
			let "diff=$2-$1"
			if [ $1 = "-manu" ] || [ $1 = "manu" ]
			then
				let "diff=$diff-60"
			fi

			if [ $diff -gt 60 ]
			then
				let "min=$diff/60"
				let "sec=$diff%60"
				if [ $min -gt 60 ]
				then
					let "heu=$min/60"
					let "min=$min%60"
				else
					heu=0
				fi
			fi

			if [ $heu -eq 0 ]
			then
				if [ $min -eq 0 ]
				then
					printMsg $3 $formSurligne"Temps écoulé"$formNormal" : "$formGras$sec" seconde(s)"$formNormal$formSaut
				else
					printMsg $3 $formSurligne"Temps écoulé"$formNormal" : "$formGras$min" minute(s) et "$sec" seconde(s)"$formNormal$formSaut
				fi
			else
				printMsg $3 $formSurligne"Temps écoulé"$formNormal" : "$formGras$heu" heure(s) "$min" minute(s) et "$sec" seconde(s)"$formNormal$formSaut
			fi
		}

		saveBdd(){
			printMsg $1 $formGrasSurligne"Sauvegarde des BDDS"$formNormal" :"$formSaut
			for index in "${!_BDD_MYSQL[@]}"
			do
				baseDeDonnees=${_BDD_MYSQL[$index]}
				nomBaseDeDonnees=${_NOM_BDD_MYSQL[$index]}
				printMsg $1 $formMargin"Sauvegarde de "$nomBaseDeDonnees$formNormal$formSautHtml
				mysqldump --user=$_USER_MYSQL --password=$_PASS_MYSQL $baseDeDonnees > $_PATH_SAUVEGARDE/$DATE-mysql-$nomBaseDeDonnees.sql
				if [ $? -ne 0 ]
				then
					printMsg $1 $formRouge" -Creation .sql NOK... "$formNormal$formSautHtml
					let "errors=$errors+1"
				else
					printMsg $1 $formVert" -Creation .sql OK... "$formNormal$formSautHtml
				fi
				bzip2 -f --best $_PATH_SAUVEGARDE/$DATE-mysql-$nomBaseDeDonnees.sql
				if [ $? -ne 0 ]
				then
					printMsg $1 $formRouge" --Compression en .bzip2 NOK... "$formNormal$formSautHtml
					let "errors=$errors+1"
				else
					printMsg $1 $formVert" --Compression en .bzip2 OK... "$formNormal$formSautHtml
				fi
			done
			find $_PATH_SAUVEGARDE -name "*.sql" -delete
		}

		saveRepertoireConfig(){
			printMsg $1 $formSaut$formGrasSurligne"Sauvegarde des répertoires de config"$formNormal" :"$formSaut
		    for index in "${!_REPERTOIRE_CONFIGURATION_CHEMIN[@]}"
		    do
		        repertoire=${_REPERTOIRE_CONFIGURATION_CHEMIN[$index]}
		        nomArchive=${_REPERTOIRE_CONFIGURATION_NOM[$index]}
		        exclusion=${_REPERTOIRE_CONFIGURATION_EXCLUSION[$index]}
		        printMsg $1 $formMargin"Sauvegarde de "$nomArchive$formNormal$formSautHtml
		        tar jcf $_PATH_SAUVEGARDE/$DATE-config-$nomArchive.tar.bz2 --exclude="'$exclusion'"    $repertoire >/dev/null 2>&1
		        if [ $? -ne 0 ]
		            then
		            printMsg $1 $formRouge" -Archivage "$nomArchive" NOK... "$formNormal$formSautHtml
		            let "errors=$errors+1"
		        else
		            printMsg $1 $formVert" -Archivage "$nomArchive" OK... "$formNormal$formSautHtml
		        fi
		    done
		}

		saveRepertoireWeb(){
			printMsg $1 $formSaut$formGrasSurligne"Sauvegarde des répertoires Web"$formNormal" :"$formSaut
		    for index in "${!_REPERTOIRE_WEB_CHEMIN[@]}"
		    do
		        repertoire=${_REPERTOIRE_WEB_CHEMIN[$index]}
		        nomArchive=${_REPERTOIRE_WEB_NOM[$index]}
		        exclusion=${_REPERTOIRE_WEB_EXCLUSION[$index]}
		        printMsg $1 $formMargin"Sauvegarde de "$nomArchive$formNormal$formSautHtml
		        tar jcf $_PATH_SAUVEGARDE/$DATE-web-$nomArchive.tar.bz2 --exclude="'$exclusion'"    $repertoire >/dev/null 2>&1
		        if [ $? -ne 0 ]
		            then
		            printMsg $1 $formRouge" -Archivage "$nomArchive" NOK... "$formNormal$formSautHtml
		            let "errors=$errors+1"
		        else
		            printMsg $1 $formVert" -Archivage "$nomArchive" OK... "$formNormal$formSautHtml
		        fi
		    done
		}

	# On enregistre le temps pour la durée du script
		DATEPD=$(date --date="$(date +'%Y-%m-%d %H:%M:%S')" +%s)

	## Switch
		case $1 in
			"-manu" | "manu")
				clear
				## Début du script avec affichage écran sans log
				echo -e "____________________________________________________________"
				echo    "*                                                          *"
				echo    "*               Sauvegarde du $DATE                   *"
				echo -e "$formSurligne*                                                          *$formNormal\n"

				# On commence par les BDDs
				saveBdd $1

				# Repertoire de configuration
				saveRepertoireConfig $1

				# Ensuite les répertoires des fichiers web
				saveRepertoireWeb $1

				echo -e "\n____________________________________________________________"
				echo    "*                                                          *"
				echo    "*           Sauvegarde du $DATE terminée !            *"
				if [ $errors -ne 0 ]
				then
					echo -e "*          $formRouge Il y a eu $errors erreur(s) de sauvegarde$formNormal            *"
				fi
				echo -e "$formSurligne*                                                          *$formNormal"


				if [ $DELETE = 'Y' ]
					then
					echo -e "\n***********************************************************************"
					echo      "*                                                                     *"
					nbsupp=`find $_PATH_SAUVEGARDE -depth -mtime +$DAYS | wc -l`
					if [ $nbsupp -ne 0 ]
					then
						find $_PATH_SAUVEGARDE -depth -mtime +$DAYS -delete
						if [ $? -eq 0 ]
						then
							echo -e   "*        $formVert Suppression OK des sauvegardes de plus de $DAYS jours$formNormal          *"
						else
							echo -e   "*        $formRouge Suppression NOK des sauvegardes de plus de $DAYS jours$formNormal         *"
						fi
					else
						echo -e   "*                   $formVert Pas de sauvegardes à supprimer$formNormal                   *"
					fi
					echo      "*                                                                     *"
					echo -e   "***********************************************************************\n"
				fi

				## Transfert FTP des sauvegardes du jour si $FTP est à Y et message
				if [ $FTP = 'Y' ]
				then
					echo -e "\n***********************************************************************"
					echo      "*                                                                     *"
					echo      "*               Transfert FTP OK des sauvegardes du jour              *"
					echo      "*                                                                     *"
					echo -e   "***********************************************************************\n"
				fi

				## Message temps d'éxecution
				DATEPF=$(date --date="$(date +'%Y-%m-%d %H:%M:%S')" +%s)
				tpsexe $DATEPD $DATEPF $1

				## Espace pour séparer l'invite de shell
				echo ''
			;;
			"-autoc" | "autoc")
				## Début du script avec log complet sans affichage écran.
				cat $topHtml > $_LOG
				echo "<div style=\"display:table;border:1px inset #000;text-align:center;width:350px;height:45px;\">" >> $_LOG
				echo "<h3 style=\"display:table-cell;vertical-align:middle;\">Sauvegarde du $DATE</h3>" >> $_LOG
				echo "</div>$formSautHtml$formSautHtml" >> $_LOG

				# On commence par les BDDs
				saveBdd $1

				# Repertoire de configuration
				saveRepertoireConfig $1

				# Ensuite les répertoires des fichiers web
				saveRepertoireWeb $1

				echo "$formSautHtml$formSautHtml<div style=\"display:table;border:1px inset #000;text-align:center;width:350px;height:50px;\">" >> $_LOG
				echo "<div style=\"display:table-cell;vertical-align:middle;margin:0;\">" >> $_LOG
				echo "<h3 style=\"margin:0;\">Sauvegarde du $DATE terminée !</h3>" >> $_LOG
				if [ $errors -ne 0 ]
				then
					echo "<h4 style=\"margin:0;color:red\">Il y a eu $errors erreur(s) de sauvegarde</h4>" >> $_LOG
				fi
				echo "</div></div>$formSautHtml" >> $_LOG

				## Pause pour la suppression complète
				sleep 1m

				if [ $DELETE = 'Y' ]
				then
					# Suppression des sauvegardes si $DELETE est à Y et Message
					echo "$formSautHtml" >> $_LOG
					echo "<div style=\"display:table;border:1px inset #000;text-align:center;width:350px;height:50px;\">" >> $_LOG
					echo "<div style=\"display:table-cell;vertical-align:middle;margin:0;\">" >> $_LOG
					nbsupp=`find $_PATH_SAUVEGARDE -depth -mtime +$DAYS | wc -l`
					if [ $nbsupp -ne 0 ]
					then
						find $_PATH_SAUVEGARDE -depth -mtime +$DAYS -delete
						if [ $? -eq 0 ]
						then
							echo "<h3 style=\"margin:0;color:green;\">Suppression OK des sauvegardes de plus de $DAYS jours</h3>" >> $_LOG
						else
							echo "<h3 style=\"margin:0;color:red;\">Suppression NOK des sauvegardes de plus de $DAYS jours" >> $_LOG
						fi
					else
							echo "<h3 style=\"margin:0;\">Pas de sauvegardes à supprimer</h3>" >> $_LOG
					fi
					echo "</div></div>$formSautHtml" >> $_LOG
				fi

				## Transfert FTP des sauvegardes du jour si $FTP est à Y et Message
				if [ $FTP = 'Y' ]
				then
					echo "$formSautHtml" >> $_LOG
					echo "<div style=\"display:table;border:1px inset #000;text-align:center;width:350px;height:50px;\">" >> $_LOG
					echo "<div style=\"display:table-cell;vertical-align:middle;margin:0;\">" >> $_LOG
					echo "<h3 style=\"margin:0;color:green;\">Transfert FTP OK des sauvegardes du jour</h3>" >> $_LOG
					echo "</div></div>$formSautHtml" >> $_LOG
				fi
				## Message temps d'éxecution
				DATEPF=$(date --date="$(date +'%Y-%m-%d %H:%M:%S')" +%s)
				tpsexe $DATEPD $DATEPF $1 >> $_LOG
				cat $footHtml >> $_LOG
				## Envoie mail
				if [ $envMail = 'Y' ]
				then
					cat $txtMail | mailx -s "Sauvegarde du $DATE" -a $_LOG john.doe@domain.com
				fi
			;;
			"-debug" | "debug")
				## Pour debug
				clear
					echo -e "**************************************************************"
					echo    "*                                                            *"
					echo    "*                          DEBUGAGE                          *"
					echo -e "*                       Version v$_VERSION                       *"
					echo -e "*                       Du $_DERNIERE_MODIF                        *"
					echo    "*                                                            *"
					echo    "**************************************************************"
					printMsg $1 $formGrasSurligne"Liste des variables"$formNormal" :"$formSaut
					# Liste des variables
						echo -e "$formGras  DATE                 $formNormal: $DATE"
						echo -e "$formGras  DATEHEURE            $formNormal: $DATEHEURE"
						echo -e "$formGras  _PATH_SAUVEGARDE     $formNormal: $_PATH_SAUVEGARDE"
						echo -e "$formGras  _HOST_MYSQL          $formNormal: $_HOST_MYSQL"
						echo -e "$formGras  _USER_MYSQL          $formNormal: $_USER_MYSQL"
						echo -e "$formGras  _PASS_MYSQL          $formNormal: $_PASS_MYSQL"
						echo -e "$formGras  _LOG                 $formNormal: $_LOG"
						echo -e "$formGras  DELETE               $formNormal: $DELETE"
						echo -e "$formGras  DAYS                 $formNormal: $DAYS"
						echo -e "$formGras  FTP                  $formNormal: $FTP"
						echo -e "$formGras  HOSTFTP              $formNormal: $HOSTFTP"
						echo -e "$formGras  USERFTP              $formNormal: $USERFTP"
						echo -e "$formGras  PWDFTP               $formNormal: $PWDFTP"
						echo -e "$formGras  envMail              $formNormal: $envMail"
						echo -e "$formGras  errors               $formNormal: $errors"
						echo -e "$formGras  nbsupp               $formNormal: $nbsupp"
						echo -e "$formGras  txtMail              $formNormal: $txtMail"
						echo -e "$formGras  topHtml              $formNormal: $topHtml"
						echo -e "$formGras  footHtml             $formNormal: $footHtml"
						echo -e "$formGras  _TEST                $formNormal: $_TEST"
						echo -e "\n"
					# Affichage BDD à sauvegarder
						printMsg $1 $formGrasSurligne"Liste des base de données à sauvegarder"$formNormal" :"$formSaut
						for index in "${!_BDD_MYSQL[@]}"; do printf "  |\033[4m %-67s \033[0m %s\n" "${_BDD_MYSQL[$index]}" "${_NOM_BDD_MYSQL[$index]}"; done
						echo -e "\n"
					# Affichage des répertoires CONF à sauvegarder
						printMsg $1 $formGrasSurligne"Liste des répertoires de configuration à sauvegarder"$formNormal" :"$formSaut
						for index in "${!_REPERTOIRE_CONFIGURATION_CHEMIN[@]}"; do printf "  |\033[4m %-67s \033[0m %s\n" "${_REPERTOIRE_CONFIGURATION_CHEMIN[$index]}" "${_REPERTOIRE_CONFIGURATION_NOM[$index]}"; done
						echo -e "\n"
					# Affichage des répertoires WWW à sauvegarder
						printMsg $1 $formGrasSurligne"Liste des répertoires de sites WEB à sauvegarder"$formNormal" :"$formSaut
						for index in "${!_REPERTOIRE_WEB_CHEMIN[@]}"; do printf "  |\033[4m %-67s \033[0m %s\n" "${_REPERTOIRE_WEB_CHEMIN[$index]} --exclude='${_REPERTOIRE_WEB_EXCLUSION[$index]}'" "${_REPERTOIRE_WEB_NOM[$index]}"; done
					echo -e "\n"
			;;
			"-help" | "help")
				## Affichage du help
					echo "sauvegarde.sh permet la sauvegarde des base de données MySQL, des fichiers des sites web et de la configuration pour le web."
					printf "\n   %bVersion%b : %b%s%b  du %b%s%b\n" "$surligne" "$normal" "$gras" "$_VERSION" "$normal" "$gras" "$_DERNIERE_MODIF" "$normal"
					printf "\n   %bUtilisation%b : ./sauvegarde.sh [paramètre1]\n" "$surligne" "$normal"
					echo -e "\n   [-manu    | manu]           Mode manuelle, aucun log tout est affiché à l'écran"
					echo      "   [-autoc   | autoc]          Mode automatique avec un log complet (contient les erreurs)"
					echo      "   [-debug   | debug]          N'affiche que les variables à l'écran, ne réalise pas de backup"
					echo      "   [-help    | help]           Affiche ce message à l'écran"
					echo      "   [-readme  | readme]         Affiche le readme"
					echo      ""
					printf "\n   %bCompression utilisée%b : \n" "$surligne" "$normal"
					echo -e   "\n   Tous les fichiers (Configuration et Web) sont compressés en bzip2 en utilisant l'utilitaire tar."
					echo        "   Les dumps (.sql) sont aussi compressés en bzip2 en utilisant l'utilitaire bzip2 (sans tar)."
					echo      ""
					echo -e "\n   Pour une configuration plus complète de ce script, merci de se reporter au readme"
					printf "   %bPour lire le readme utiliser le paramètre%b : %breadme%b ou %b-readme%b\n\n" "$surligne" "$normal" "$gras" "$normal" "$gras" "$normal"
				#
			;;
			"-readme" | "readme")
				more $_PATH_SCRIPT/readme.txt
			;;
			"-test" | "test")
				declare -F
			;;
			*)
				## Affichage du help
					exec $0 -help
			;;
		esac
	## Fin du Switch et du script
