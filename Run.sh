archmenu(){
	if [ "${1}" = "" ]; then
		nextitem="."
	else
		nextitem=${1}
	fi
	options=()
	options+=("${txtsethostname}" "/etc/hostname")
	options+=("${txtsetkeymap}" "/etc/vconsole.conf")
	options+=("${txtsetfont}" "/etc/vconsole.conf (${txtoptional})")
	options+=("${txtsetlocale}" "/etc/locale.conf, /etc/locale.gen")
	options+=("${txtsettime}" "/etc/localtime")
	options+=("${txtsetrootpassword}" "")
	options+=("${txtgenerate//%1/fstab}" "")
	if [ "${luksdrive}" = "1" ]; then
		options+=("${txtgenerate//%1/crypttab}" "")
	fi
	if [ "${luksroot}" = "1" ]; then
		options+=("${txtgenerate//%1/mkinitcpio.conf-luks}" "(encrypt hooks)")
	fi
	if [ "${isnvme}" = "1" ]; then
		options+=("${txtgenerate//%1/mkinitcpio.conf-nvme}" "(nvme module)")
	fi
	options+=("${txtedit//%1/fstab}" "(${txtoptional})")
	options+=("${txtedit//%1/crypttab}" "(${txtoptional})")
	options+=("${txtedit//%1/mkinitcpio.conf}" "(${txtoptional})")
	options+=("${txtedit//%1/mirrorlist}" "(${txtoptional})")
	options+=("${txtbootloader}" "")
	options+=("${txtextrasmenu}" "")
	options+=("archdi" "${txtarchdidesc}")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txtarchinstallmenu}" --menu "" --cancel-button "${txtback}" --default-item "${nextitem}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		case ${sel} in
			"${txtsethostname}")
				archsethostname
				nextitem="${txtsetkeymap}"
			;;
			"${txtsetkeymap}")
				archsetkeymap
				nextitem="${txtsetlocale}"
			;;
			"${txtsetfont}")
				archsetfont
				nextitem="${txtsetlocale}"
			;;
			"${txtsetlocale}")
				archsetlocale
				nextitem="${txtsettime}"
			;;
			"${txtsettime}")
				archsettime
				nextitem="${txtsetrootpassword}"
			;;
			"${txtsetrootpassword}")
				archsetrootpassword
				nextitem="${txtgenerate//%1/fstab}"
			;;
			"${txtgenerate//%1/fstab}")
				archgenfstabmenu
				if [ "${luksdrive}" = "1" ]; then
					nextitem="${txtgenerate//%1/crypttab}"
				else
					if [ "${luksroot}" = "1" ]; then
						nextitem="${txtgenerate//%1/mkinitcpio.conf-luks}"
					else
						if [ "${isnvme}" = "1" ]; then
							nextitem="${txtgenerate//%1/mkinitcpio.conf-nvme}"
						else
							nextitem="${txtbootloader}"
						fi
					fi
				fi
			;;
			"${txtgenerate//%1/crypttab}")
				archgencrypttab
				if [ "${luksroot}" = "1" ]; then
					nextitem="${txtgenerate//%1/mkinitcpio.conf-luks}"
				else
					if [ "${isnvme}" = "1" ]; then
						nextitem="${txtgenerate//%1/mkinitcpio.conf-nvme}"
					else
						nextitem="${txtbootloader}"
					fi
				fi
			;;
			"${txtgenerate//%1/mkinitcpio.conf-luks}")
				archgenmkinitcpioluks
				if [ "${isnvme}" = "1" ]; then
					nextitem="${txtgenerate//%1/mkinitcpio.conf-nvme}"
				else
					nextitem="${txtbootloader}"
				fi
			;;
			"${txtgenerate//%1/mkinitcpio.conf-nvme}")
				archgenmkinitcpionvme
				nextitem="${txtbootloader}"
			;;
			"${txtedit//%1/fstab}")
				${EDITOR} /mnt/etc/fstab
				nextitem="${txtedit//%1/fstab}"
			;;
			"${txtedit//%1/crypttab}")
				${EDITOR} /mnt/etc/crypttab
				nextitem="${txtedit//%1/crypttab}"
			;;
			"${txtedit//%1/mkinitcpio.conf}")
				archeditmkinitcpio
				nextitem="${txtedit//%1/mkinitcpio.conf}"
			;;
			"${txtedit//%1/mirrorlist}")
				${EDITOR} /mnt/etc/pacman.d/mirrorlist
				nextitem="${txtedit//%1/mirrorlist}"
			;;
			"${txtbootloader}")
				archbootloadermenu
				nextitem="${txtextrasmenu}"
			;;
			"${txtextrasmenu}")
				archextrasmenu
				nextitem="archdi"
			;;
			"archdi")
				installarchdi
				nextitem="archdi"
			;;
		esac
		archmenu "${nextitem}"
	fi
}
archchroot(){
	echo "arch-chroot /mnt /root"
	cp ${0} /mnt/root
	chmod 755 /mnt/root/$(basename "${0}")
	arch-chroot /mnt /root/$(basename "${0}") --chroot ${1} ${2}
	rm /mnt/root/$(basename "${0}")
	echo "exit"
}
archsethostname(){
	hostname=$(whiptail --backtitle "${apptitle}" --title "${txtsethostname}" --inputbox "" 0 0 "archlinux" 3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"${hostname}\" > /mnt/etc/hostname"
		echo "${hostname}" > /mnt/etc/hostname
		pressanykey
	fi
}
archsetkeymap(){
	#items=$(localectl list-keymaps)
	#options=()
	#for item in ${items}; do
	#  options+=("${item}" "")
	#done
	items=$(find /usr/share/kbd/keymaps/ -type f -printf "%f\n" | sort -V)
	options=()
	defsel=""
	for item in ${items}; do
		if [ "${item%%.*}" == "${keymap}" ]; then
			defsel="${item%%.*}"
		fi
		options+=("${item%%.*}" "")
	done
	keymap=$(whiptail --backtitle "${apptitle}" --title "${txtsetkeymap}" --menu "" --default-item "${defsel}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"KEYMAP=${keymap}\" > /mnt/etc/vconsole.conf"
		echo "KEYMAP=${keymap}" > /mnt/etc/vconsole.conf
		pressanykey
	fi
}
archsetfont(){
	items=$(find /usr/share/kbd/consolefonts/*.psfu.gz -printf "%f\n")
	options=()
	for item in ${items}; do
		options+=("${item%%.*}" "")
	done
	vcfont=$(whiptail --backtitle "${apptitle}" --title "${txtsetfont} (${txtoptional})" --menu "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"FONT=${vcfont}\" >> /mnt/etc/vconsole.conf"
		echo "FONT=${vcfont}" >> /mnt/etc/vconsole.conf
		pressanykey
	fi
}
archsetlocale(){
	items=$(ls /usr/share/i18n/locales)
	options=()
	defsel=""
	for item in ${items}; do
		if [ "${defsel}" == "" ]&&[ "${keymap::2}" == "${item::2}" ]; then
			defsel="${item}"
		fi
		options+=("${item}" "")
	done
	locale=$(whiptail --backtitle "${apptitle}" --title "${txtsetlocale}" --menu "" --default-item "${defsel}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ "$?" = "0" ]; then
		clear
		echo "echo \"LANG=${locale}.UTF-8\" > /mnt/etc/locale.conf"
		echo "LANG=${locale}.UTF-8" > /mnt/etc/locale.conf
		echo "echo \"LC_COLLATE=C\" >> /mnt/etc/locale.conf"
		echo "LC_COLLATE=C" >> /mnt/etc/locale.conf
		echo "sed -i '/#${locale}.UTF-8/s/^#//g' /mnt/etc/locale.gen"
		sed -i '/#'${locale}'.UTF-8/s/^#//g' /mnt/etc/locale.gen
		archchroot setlocale
		pressanykey
	fi
}
archsetlocalechroot(){
	echo "locale-gen"
	locale-gen
	exit
}
archsettime(){
	items=$(ls -l /mnt/usr/share/zoneinfo/ | grep '^d' | gawk -F':[0-9]* ' '/:/{print $2}')
	options=()
	for item in ${items}; do
		options+=("${item}" "")
	done
	timezone=$(whiptail --backtitle "${apptitle}" --title "${txtsettime}" --menu "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	items=$(ls /mnt/usr/share/zoneinfo/${timezone}/)
	options=()
	for item in ${items}; do
		options+=("${item}" "")
	done
	timezone=${timezone}/$(whiptail --backtitle "${apptitle}" --title "${txtsettime}" --menu "" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	clear
	echo "ln -sf /mnt/usr/share/zoneinfo/${timezone} /mnt/etc/localtime"
	ln -sf /usr/share/zoneinfo/${timezone} /mnt/etc/localtime
	pressanykey
	options=()
	options+=("UTC" "")
	options+=("Local" "")
	sel=$(whiptail --backtitle "${apptitle}" --title "${txtsettime}" --menu "${txthwclock}" 0 0 0 \
		"${options[@]}" \
		3>&1 1>&2 2>&3)
	if [ ! "$?" = "0" ]; then
		return 1
	fi
	
	clear
	case ${sel} in
		"${txthwclockutc}")
			archchroot settimeutc
		;;
		"${txthwclocklocal}")
			archchroot settimelocal
		;;
	esac
	
#	if (whiptail --backtitle "${apptitle}" --title "${txtsettime}" --yesno "${txtuseutcclock}" 0 0) then
#		clear
#		archchroot settimeutc
#	else
#		clear
#		archchroot settimelocal
#	fi
	pressanykey
}
archsettimeutcchroot(){
	echo "hwclock --systohc --utc"
	hwclock --systohc --utc
	exit
}
archsettimelocalchroot(){
	echo "hwclock --systohc --localtime"
	hwclock --systohc --localtime
	exit
}
archsetrootpassword(){
	clear
	archchroot setrootpassword
	pressanykey
}
archsetrootpasswordchroot(){
	echo "passwd root"
	passed=1
	while [[ ${passed} != 0 ]]; do
		passwd root
		passed=$?
	done
	exit
}
