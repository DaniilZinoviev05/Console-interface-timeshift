#! /bin/bash

###
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
echo $SCRIPT_DIR
CONF="$(realpath "$SCRIPT_DIR/../setgs.conf")"
echo $CONF
echo "$(realpath "$SCRIPT_DIR/..")"
###
echo -e "\e[36m####################################################################################\e[0m"

cat << "EOF"
▗▄▄▖  ▗▄▖  ▗▄▄▖▗▖ ▗▖ ▗▄▖  ▗▄▄▖▗▄▄▄▖ ▗▄▄▖
▐▌ ▐▌▐▌ ▐▌▐▌   ▐▌▗▞▘▐▌ ▐▌▐▌   ▐▌   ▐▌
▐▛▀▘ ▐▛▀▜▌▐▌   ▐▛▚▖ ▐▛▀▜▌▐▌▝▜▌▐▛▀▀▘ ▝▀▚▖
▐▌   ▐▌ ▐▌▝▚▄▄▖▐▌ ▐▌▐▌ ▐▌▝▚▄▞▘▐▙▄▄▖▗▄▄▞▘

EOF

echo "Install the required packages / Установим необходимы пакеты..."
source $SCRIPT_DIR/packages.sh
###
echo -e "\e[36m####################################################################################\e[0m"

cat << "EOF"
 ▗▄▄▖▗▄▄▄▖▗▄▄▄▖▗▄▄▄▖▗▄▄▄▖▗▖  ▗▖ ▗▄▄▖ ▗▄▄▖
▐▌   ▐▌     █    █    █  ▐▛▚▖▐▌▐▌   ▐▌
 ▝▀▚▖▐▛▀▀▘  █    █    █  ▐▌ ▝▜▌▐▌▝▜▌ ▝▀▚▖
▗▄▄▞▘▐▙▄▄▖  █    █  ▗▄█▄▖▐▌  ▐▌▝▚▄▞▘▗▄▄▞▘

EOF

source $SCRIPT_DIR/settings.sh
echo -e "\e[36m####################################################################################\e[0m"
###

############## MAIN FUNCTIONS ##############
createBackupFunc() {
	clear
	echo -e "En: \e[34mHere you can create a snapshot that will be automatically added to grub.\e[0m"
	echo -e "Ru: \e[34mЗдесь Вы можете создать снимок системы, который сразу добавится в grub.\e[0m\n"
	echo -e "\e[32m| 1 - Move on to create / Перейти к созданию\e[0m\n"
	echo -e "\e[34m| 2 - Back / Назад\n\e[0m\n"
	read -p "Enter value / Введите действие: " sub_action

	case $sub_action in
	1)
		echo -e "\n"
		read -p "Enter comment / Введите комментарий для бэкапа: " comment
		sudo timeshift --create --comments "$comment"
		sudo grub-mkconfig -o /boot/grub/grub.cfg
		break
	;;
	2)
		break
	;;
	*)
		echo -e "\e[31mInvalid value / Некорректный ввод \e[0m"
	;;
	esac
}

restoreBackupFunc() {
	clear
	echo -e "En: \e[34mHere you can restore your system.\e[0m"
	echo -e "Ru: \e[34mЗдесь Вы можете восстановить систему.\e[0m\n"
	echo -e "\e[32m| 1 - Move on to restore / Перейти к восстановлению системы\e[0m\n"
	echo -e "\e[34m| 2 - Back / Назад\n\e[0m\n"
	read -p "Enter value / Введите действие: " sub_action

	case $sub_action in
	1)
		echo -e "\n"
		echo -e "\e[32m$(sudo timeshift --list)\e[0m"
		read -p "Enter backup name / Введите название бэкапа: " name
		sudo timeshift --restore --snapshot $name
		break
	;;
	2)
		break
	;;
	*)
		echo -e "\e[31mInvalid value / Некорректный ввод \e[0m"
	;;
	esac
}

autoBackupFunc() {
	clear
	echo -e "En: \e[34mHere you can create autobackups.\e[0m"
	echo -e "Ru: \e[34mЗдесь Вы можете настроить бэкапы по расписанию.\e[0m\n"
	echo -e "\e[32m| 1 - Create autobackup / Создать автобэкап\e[0m\n"
	echo -e "\e[32m| 2 - Clear autobackups / Очистить бэкапы по расписанию\e[0m\n"
	echo -e "\e[34m| 3 - Back / Назад\n\e[0m\n"
	read -p "Enter value / Введите действие: " sub_action
	case $sub_action in
		1)
			clear
			read -p "Comment / Введите комментарий для бэкапа: " comment
			read -p "Month / Введите месяц (число, например, 9 для сентября): " month
			read -p "Day of the week / Введите день недели (0 для воскресенья, 1 для понедельника и т.д.): " day
			read -p "Enter time / Введите время (например, 12:45): " time

			IFS=':' read -r hour minute <<< "$time"

			if [[ ! $hour =~ ^[0-9]+$ ]] || [[ ! $minute =~ ^[0-9]+$ ]] || [[ "$hour" -lt 0 ]] || [[ "$hour" -gt 23 ]] || [[ "$minute" -lt 0 ]] || [[ "$minute" -gt 59 ]]; then
			    echo "Incorrect time / Некорректное время."
			    exit 1
			fi

			crontab -l > cron
			(crontab -l 2>/dev/null; echo "$minute $hour * $month $day sudo timeshift --create --comments \"$comment\"") >> cron
			(crontab -l 2>/dev/null; echo "$minute $hour * $month $day sudo grub-mkconfig -o /boot/grub/grub.cfg") >> cron
			(crontab -l 2>/dev/null; echo "$minute $hour * $month $day echo "Backup \"$comment\" created successfully / Бэкап \"$comment\" успешно создан." | mailx -s "BACKUP-REPORT" "$EMAIL"") >> cron
			sudo crontab cron
			rm cron
			break
		;;

		2)
			clear
			echo -e "\n\e[34m### \e[32mCOMMANDS IN CRON(Script delete this commands)\e[0m / \e[32mКОМАНДЫ CRON(Скрипт удалит команды снизу)\e[34m ###\e[0m\n"
			echo -e "\e[31m$(sudo crontab -l)\e[0m"
			echo -e "\e[34m#################################################################################################\e[0m\n"
			echo -e "\e[31m//////////////////////////////////////////////////////////////////\n"
			sudo crontab -r
			echo -e "\n//////////////////////////////////////////////////////////////////\e[0m"
			echo -e "\n\e[34m### \e[32mCOMMANDS IN CRON(Now)\e[0m / \e[32mКОМАНДЫ CRON(Текущее состояние)\e[34m ###\e[0m\n"
			echo -e "\e[31m$(sudo crontab -l)\e[0m"
			echo -e "\e[34m###############################################################\e[0m\n"
			sleep 10
			break
		;;

	       *)
	       		echo "Incorrect value / Неверный ввод, попробуйте снова."
	       		break
	       	;;
	esac
}

deleteBackupFunc() {
	clear
	echo -e "En: \e[34mHere you can delete your backup.\e[0m"
	echo -e "Ru: \e[34mЗдесь Вы можете удалить бэкап.\e[0m\n"
	echo -e "\e[32m| 1 - Move on to delete / Перейти к удалению\e[0m\n"
	echo -e "\e[34m| 2 - Back / Назад\n\e[0m\n"
	read -p "Enter value / Введите действие: " sub_action

	case $sub_action in
	1)
		clear
		echo -e "\e[34m################################## \e[32mBACKUPS\e[0m / \e[32mБЭКАПЫ\e[34m ##################################\e[0m"
		echo -e "\e[32m$(sudo timeshift --list)\e[0m"
		echo -e "\e[34m#####################################################################################\e[0m\n"
		read -p "Enter backup name (name! Not comment!) / Введите название бэкапа (из поля name, не комментарий!): " name
		sudo timeshift --delete --snapshot $name
	;;
	2)
		break
	;;
	*)
		clear
		echo -e "\n\e[31m(-_-)/ |Incorrect value / Неправильный ввод|\e[0m"
		break
	;;
	esac
}

changeEmailFunc() {
	clear
	EXPECTED_ENTRY="user_email"

	if [[ -f $CONF ]]; then
		echo -e "\n########################################################"
		echo "$CONF file found / Файл $CONF найден"

		if grep -q "^$EXPECTED_ENTRY=" "$CONF"; then
			echo "The $EXPECTED_ENTRY entry was found in the file / Запись $EXPECTED_ENTRY найдена в файле"

			read -p "Enter email / Введите email:" EMAIL
			echo "Updating the $EXPECTED_ENTRY entry with the new value / Обновление записи $EXPECTED_ENTRY новым значением"

			sudo sed -i "s/^$EXPECTED_ENTRY=.*/$EXPECTED_ENTRY=\"$EMAIL\"/" "$CONF"

			echo "Entry updated / Запись обновлена"
		else
			echo "Entry $EXPECTED_ENTRY not found in the file / Запись $EXPECTED_ENTRY не найдена в файле"
		fi
	else
		echo "$CONF file not found / Файл $CONF не найден"
	fi
	echo -e "########################################################\n"
}

deleteScriptFunc() {
	clear
	sudo mv /usr/share/applications/script.desktop "$(realpath "$SCRIPT_DIR/..")"
	sudo mv "$(realpath "$SCRIPT_DIR/../timeshift-gtk.desktop")"  /usr/share/applications/
	echo -e "\n\e[34mAfter 10 seconds the script will be deleted \_(-_-)  / Через 10 секунд скрипт будет удален \_(-_-)\e[0m\n"
	echo -e "\e[31m! Will be deleted / Будет удален: "$(realpath "$SCRIPT_DIR/..")"\e[0m\n"
	sleep 10
	#cd ~
	#sudo rm -rf "$(realpath "$SCRIPT_DIR/..")"
}
######################################

while true; do

echo -e "\e[32m"

cat << "EOF"
  _      _                                _        _                _
 | |    (_)                              | |      | |              | |
 | |     _ _ __  _   ___  __   __ _ _   _| |_ ___ | |__   __ _  ___| | ___   _ _ __
 | |    | | '_ \| | | \ \/ /  / _` | | | | __/ _ \| '_ \ / _` |/ __| |/ / | | | '_ \
 | |____| | | | | |_| |>  <  | (_| | |_| | || (_) | |_) | (_| | (__|   <| |_| | |_) |
 |______|_|_| |_|\__,_/_/\_\  \__,_|\__,_|\__\___/|_.__/ \__,_|\___|_|\_\\__,_| .__/
	                                                                      | |
	                                                                      |_|
EOF

echo -e "\e[0m"

	echo -e "\n\e[33mUser:\e[0m $(whoami) \e[34m|\e[0m \e[33mTimeshift:\e[0m $(timeshift --version)"

	echo -e "\e[32m\n| 1 - Backups / Бэкапы\n\e[0m"
	echo -e "\e[32m| 2 - Settings / Настройки\n\e[0m"
	echo -e "\e[32m| 3 - Run / Запустить timeshift\n\e[0m"
	echo -e "\e[34m| 4 - Exit / Выход\n\e[0m\n"
	read -p "Enter value / Введите действие: " action

	while true; do
		case $action in
		1)
			clear
			echo -e "\e[32m\n| 1 - Create backup / Создать бэкап\n\e[0m"
			echo -e "\e[32m| 2 - View backups / Посмотреть бэкапы\n\e[0m"
			echo -e "\e[32m| 3 - Restore system / Восстановить систему\n\e[0m"
			echo -e "\e[32m| 4 - Set up auto backups / Настроить автобэкапы\n\e[0m"
			echo -e "\e[32m| 5 - Delete backup / Удалить бэкап\n\e[0m"
			echo -e "\e[34m| 6 - Back / Назад\n\e[0m\n"
			read -p "Enter value / Введите действие: " sub_action

				case $sub_action in
				1)
					createBackupFunc
				;;

				2)
					clear
					echo -e "\e[34m################################## \e[32mBACKUPS\e[0m / \e[32mБЭКАПЫ\e[34m ##################################\e[0m"
					sudo timeshift --list
					echo -e "\e[34m#####################################################################################\e[0m"
					break
				;;

				3)
					restoreBackupFunc
				;;

				4)
					autoBackupFunc
				;;
				5)
					deleteBackupFunc
				;;

				6)
					clear
					break
				;;
			esac
		;;
		2)
			clear
			echo -e "\n\e[32m| 1 - Change Email / Изменить почту\n\e[0m"
			echo -e "\e[32m| 2 - Delete script / Удалить скрипт\n\e[0m"
			echo -e "\e[34m| 3 - Back / Назад\n\e[0m\n"
			read -p "Enter value / Введите действие: " settings_action
			case $settings_action in
			1)
				changeEmailFunc
			;;
			2)
				deleteScriptFunc
			;;
			3)
				clear
				break
			;;
			*)
				clear
				echo -e "\n\e[31m(-_-)/ |Incorrect value / Неправильный ввод|\e[0m"
				break
			;;
			esac
		;;
		3)
			clear
			sudo timeshift-gtk
			break
		;;
		4)
			exit
		;;
		*)
			clear
			echo -e "\n\e[31m(-_-)/ |Incorrect value / Неправильный ввод|\e[0m"
			break
		;;
		esac
	done
done
