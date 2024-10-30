#!/bin/bash
#Created by Jan Molina

LRED="\e[91m"
LGREEN="\e[92m"
LYELLOW="\e[93m"
LBLUE="\e[94m"
LMAGENTA="\e[95m"
LCYAN="\e[96m"
LGREY="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

STDCOLOR="\e[96m"
ERRCOLOR="\e[91m"

ERRFILE="/var/log/install/error.log"

LOCALE=$(locale | grep "LANG" | cut -d"=" -f2-)


function isroot() {
	if [ $(whoami) != "root" ]; then
	echo -e "$ERRCOLOR Necesitas root $RESET"
	exit 1
	fi
}

function test-err() {
	if [ $1 -ne 0 ]; then
		echo -e "$ERRCOLOR"
		cat /var/log/install/error.log
		echo -e "$RESET"
		exit
	fi
}

function internet() {
	if [ $1 -ne 0 ]; then
        echo -e "$ERRCOLOR Necesitas conexión a internet $RESET"
        exit
	fi
}

function test-ping() {
	if [ $1 -ne 0 ]; then
        echo -e "$STDCOLOR  Conexion: \t$LRED     Error $RESET"
        echo -e "\n"
        echo -e "$STDCOLOR -------------------------------- $RESET"
        exit
    else
        echo -e "$STDCOLORN  Conexion: \t$LGREEN     OK $RESET"
fi
}

clear
isroot
ping -c 1 -W 1 google.com >>/dev/null 2>&1
internet $?

# List for chosing what to install
declare -a scripts
scripts=("GLPI" "Wordpress" "KMS" "Moodle" "Prestashop")

mkdir /var/log/install

# List for chosing what to do
declare -a what
what=("Install" "Red" "Hardware")

while true; do
	clear
	

	for i in ${!what[@]}; do
		echo -e "$i) ${what[$i]}"
	done

	echo -e "Que quieres hacer"
	read -p ">" hacer

	# Install
	case $hacer in
		0|[Ii]|[Ii][Nn][Ss][Tt][Aa][Ll][Ll])
			clear
			
			echo -e "Que quieres instalar"

			for i in ${!scripts[@]}; do
				echo -e "$i) ${scripts[$i]}"
			done

			read -p ">" script

			while true; do
				while true; do
					case $script in
						# GLPI
						0|[Gg]|[Gg][Ll][Pp][Ii])
							LOGFILE="/var/log/install/glpi.log"
							clear
							

							echo -e "$STDCOLOR ------------------ $RESET"
							echo -e "$STDCOLOR Instalador de GLPI $RESET"
							echo -e "$STDCOLOR ------------------ $RESET"

							echo -e "$STDCOLOR De donde lo quieres instalar $RESET"
							declare -a web
							web=("172.31.0.5" "github")

							for i in ${!web[@]}; do
								echo -e "$i) ${web[$i]}"
							done

							read -p ">" webserver

							echo -e "$STDCOLOR Instalando GLPI $RESET"
							rm /var/www/html/index.html >>$LOGFILE 2>$ERRFILE
							case $webserver in
								0)
									wget 172.31.0.5/glpi/glpi.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									apt install -y unzip >>$LOGFILE 2>$ERRFILE
									test-err $?
									unzip glpi.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									rm glpi.zip >>/dev/null 2>&1
									;;
								1)
									wget https://github.com/glpi-project/glpi/releases/download/10.0.7/glpi-10.0.7.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									tar -xzvf glpi-10.0.7.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									rm glpi-10.0.7.tgz >>/dev/null 2>&1
									;;
								[Ee]|[Ee][Xx][Ii][Tt])
									break 2
									;;
								*)
									echo "No valido"
									break
									;;
							esac

							echo -e "$STDCOLOR Que nombre quieres para tu base de datos $RESET"
							read -p ">" database
							echo -e "$STDCOLOR Que nombre de usuario quieres para tu base de datos $RESET"
							read -p ">" username
							echo -e "$STDCOLOR Que contraseña quieres para tu base de datos $RESET"
							read -p ">" password
							
							echo -e "$STDCOLOR Instalando dependencias $RESET"
							apt-get update >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt-get install -y apache2 mariadb-server php php-mysql php-json php-fileinfo php-dom php-simplexml php-curl php-gd php-intl >>$LOGFILE 2>$ERRFILE
							test-err $?

							mv glpi/* /var/www/html >>$LOGFILE 2>$ERRFILE
							test-err $?
							rm -r glpi >>/dev/null 2>&1

							echo -e "$STDCOLOR Creando base de datos $RESET"
							mysql -u root -e "create database $database;"
							test-err $?
							mysql -u root -e "create user '$username'@'localhost' identified by '$password';"
							test-err $?
							mysql -u root -e "grant all privileges on glpi.* to '$username'@'localhost';"
							test-err $?
							mysql -u root -e "flush privileges;"
							test-err $?

							echo -e "$STDCOLOR Dando permisos $RESET"
							chown -R www-data:www-data /var/www/html/* >>$LOGFILE 2>$ERRFILE
							test-err $?
							chmod -R 755 /var/www/html/* >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Reiniciando servidor web $RESET"
							systemctl restart apache2 >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$LYELLOW Abre tu GLPI en el navegador $RESET"
							echo -e "$LGREY Base de datos: $database $RESET"
							echo -e "$LGREY Usuario: $username $RESET"
							echo -e "$LGREY Contraseña: $password $RESET"

							echo -e "$LGREY Sesion de glpi $RESET"
							echo -e "$LGREY Usuario: glpi $RESET"
							echo -e "$LGREY Contraseña: glpi $RESET"
							break 2
							;;

						# Wordpress
						1|[Ww]|[Ww][Oo][Rr][Dd][Pp][Rr][Ee][Ss])
							LOGFILE="/var/log/install/wordpress.log"
							clear
							

							echo -e "$STDCOLOR ----------------------- $RESET"
							echo -e "$STDCOLOR Instalador de Wordpress $RESET"
							echo -e "$STDCOLOR ----------------------- $RESET"

							echo -e "$STDCOLOR De donde lo quieres instalar $RESET"
							declare -a web
							web=("172.31.0.5" "official website")

							for i in ${!web[@]}; do
								echo -e "$i) ${web[$i]}"
							done

							read -p ">" webserver

							echo -e "$STDCOLOR Que nombre quieres para tu base de datos $RESET"
							read -p ">" database
							echo -e "$STDCOLOR Que nombre de usuario quieres para tu base de datos $RESET"
							read -p ">" username
							echo -e "$STDCOLOR Que contraseña quieres para tu base de datos $RESET"
							read -p ">" password

							echo -e "$STDCOLOR Instalando dependencias $RESET"
							apt update >>$LOGFILE 2>$ERRFILE
							apt install -y apache2 mariadb-server >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt install -y php php-mysql php-curl php-zip php-xml php-bz2 php-mbstring php-gd php-intl php-xmlrpc php-soap php-ldap >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Instalando Wordpress $RESET"
							rm /var/www/html/index.html >>$LOGFILE 2>$ERRFILE
							case $webserver in
								0)
									wget 172.31.0.5/wordpress/latest.tar.gz >>$LOGFILE 2>$ERRFILE
									test-err $?
								;;
								1)
									wget https://wordpress.org/latest.tar.gz >>$LOGFILE 2>$ERRFILE
									test-err $?
									;;
								# Cualquier otra cosa
								*)
									echo "Respuesta incorrecta"
									break
									;;
							esac
							tar -xzvf latest.tar.gz >>$LOGFILE 2>$ERRFILE
							test-err $?
							mv wordpress/* /var/www/html/ >/var/log/install/wordpress.log 2>/var/log/install/error.log
							test-err $?

							echo -e "$STDCOLOR Dando permisos $RESET"
							chown -R www-data:www-data /var/www/html >/var/log/install/wordpress.log 2>/var/log/install/error.log
							test-err $?

							echo -e "$STDCOLOR Creando base de datos $RESET"
							mysql -u root -e "create database $database;"
							test-err $?
							mysql -u root -e "create user '$username'@'localhost' identified by '$password';"
							test-err $?
							mysql -u root -e "grant all privileges on $database.* to '$username'@'localhost';"
							test-err $?
							mysql -u root -e "flush privileges;"
							test-err $?

							echo -e "$STDCOLOR Reiniciando servidor $RESET"
							systemctl restart apache2
							test-err $?

							echo -e "$STDCOLOR Wordpress instalado $RESET"
							
							echo -e "$LYELLOW Abre tu Wordpress en el navegador $RESET"
							echo -e "$LGREY Base de datos: $database $RESET"
							echo -e "$LGREY Usuario: $username $RESET"
							echo -e "$LGREY Contraseña: $password $RESET"
							break 3
							;;

						# KMS
						2|[Kk]|[Kk][Mm][Ss])
							LOGFILE="/var/log/install/kms.log"
							clear
							

							echo -e "$BOLD$STDCOLOR Instalador de servidor KMS $RESET"
							apt update >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt install -y unzip >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$BOLD$STDCOLOR Instalando archivos de KMS $RESET"
							wget https://github.com/Wind4/vlmcsd/archive/refs/heads/master.zip >>$LOGFILE 2>$ERRFILE
							test-err $?
							unzip master.zip >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$BOLD$STDCOLOR Ejecutando archivos de KMS $RESET"
							cd vlmcsd-master >>$LOGFILE 2>$ERRFILE
							apt install -y gcc make cmake >>$LOGFILE 2>$ERRFILE
							test-err $?
							make >>$LOGFILE 2>$ERRFILE
							test-err $?

							cd bin >>$LOGFILE 2>$ERRFILE
							mkdir /srv/kms >>$LOGFILE 2>$ERRFILE
							test-err $?
							cp vlmcsd /srv/kms >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$BOLD$STDCOLOR Preparando inicio de KMS $RESET"
							touch /etc/systemd/system/kms.service
							test-err $?
							chmod 755 /etc/systemd/system/kms.service
							test-err $?

							echo -e "" > /etc/systemd/system/kms.service
							echo -e "[Unit]" >> /etc/systemd/system/kms.service
							echo -e "After=network.target" >> /etc/systemd/system/kms.service
							echo -e "[Service]" >> /etc/systemd/system/kms.service
							echo -e "ExecStart=/srv/kms/vlmcsd" >> /etc/systemd/system/kms.service
							echo -e "KillMode=mixed" >> /etc/systemd/system/kms.service
							echo -e "RemainAfterExit=yes" >> /etc/systemd/system/kms.service
							echo -e "[Install]" >> /etc/systemd/system/kms.service
							echo -e "WantedBy=multi-user.target" >> /etc/systemd/system/kms.service

							echo -e "$BOLD$STDCOLOR Reiniciando servicios $RESET"
							systemctl daemon-reload >>$LOGFILE 2>$ERRFILE
							systemctl start kms.service >>$LOGFILE 2>$ERRFILE
							systemctl enable kms.service >>$LOGFILE 2>$ERRFILE

							echo -e "$BOLD$STDCOLOR KMS listo $RESET"

							get_ip=$(ip a | grep "scope global dynamic" | tr -s " " | cut -d" " -f 3-3 | cut -d"/" -f 1-1)

							clear
							

							echo -e "$BOLD$LGREY Para activar un windows haz: $RESET"
							echo -e "\t\t$BOLD$LGREY slmgr.vbs/skms [$get_ip] $RESET"
							echo -e "\t\t$BOLD$LGREY slmgr.vbs/ato $RESET"
							echo -e "$BOLD$LGREY Para comprovar que funciona: $RESET"
							echo -e "\t\t$BOLD$LGREY slmgr.vbs/dli $RESET"
							break 3
							;;

						# Moodle
						3|[Mm]|[Mm][Oo][Oo][Dd][Ll][Ee])
							LOGFILE="/var/log/install/moodle.log"
							clear
							

							echo -e "$STDCOLOR -------------------- $RESET"
							echo -e "$STDCOLOR Instalador de Moodle $RESET"
							echo -e "$STDCOLOR -------------------- $RESET"

							declare -a web
							web=("172.31.0.5" "official website")

							for i in ${!web[@]}; do
								echo -e "$i) ${web[$i]}"
							done

							read -p ">" webserver

							echo -e "$STDCOLOR Que nombre quieres para tu base de datos $RESET"
							read -p ">" database
							echo -e "$STDCOLOR Que nombre de usuario quieres para tu base de datos $RESET"
							read -p ">" username
							echo -e "$STDCOLOR Que contraseña quieres para tu base de datos $RESET"
							read -p ">" password
							apt-get update >>$LOGFILE 2>$ERRFILE

							echo -e "$STDCOLOR Instalando dependencias $RESET"
							apt-get install -y apache2 mariadb-server >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt-get install -y php php-mysql php-curl php-zip php-xml php-mbstring php-gd php-intl php-soap >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Instalando Moodle $RESET"
							rm /var/www/html/index.html >>$LOGFILE 2>$ERRFILE
							case $webserver in
								0)
									wget 172.31.0.5/moodle/moodle-4.1.1.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									tar zxvf moodle-4.1.1.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									;;
								1)
									wget https://download.moodle.org/download.php/direct/stable401/moodle-latest-401.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									tar zxvf moodle-latest-401.tgz >>$LOGFILE 2>$ERRFILE
									test-err $?
									;;
								*)
									echo "Respuesta incorrecta"
									break
							esac
							mv moodle/* /var/www/html/ >>$LOGFILE 2>$ERRFILE
							test-err $?
							mkdir /var/www/moodledata >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Dando permisos $RESET"
							chown -R www-data:www-data /var/www/moodledata/ >>$LOGFILE 2>$ERRFILE
							test-err $?
							chown -R www-data:www-data /var/www/html/ >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Creando base de datos $RESET"
							mysql -u root -e "create database $database;"
							test-err $?
							mysql -u root -e "create user '$username'@'localhost' identified by '$password';"
							test-err $?
							mysql -u root -e "grant all privileges on glpi.* to '$username'@'localhost';"
							test-err $?
							mysql -u root -e "flush privileges;"
							test-err $?

							systemctl restart apache2 >>$LOGFILE 2>$ERRFILE

							echo -e "$LYELLOW Abre tu Moodle en el navegador $RESET"
							echo -e "$LGREY Base de datos: $database $RESET"
							echo -e "$LGREY Usuario: $username $RESET"
							echo -e "$LGREY Contraseña: $password $RESET"
							break 3
							;;

						# Prestashop
						4|[Pp]|[Pp][Rr][Ee][Ss][Tt][Aa][Ss][Hh[Oo][Pp])
							LOGFILE="/var/log/install/prestashop.log"
							clear
							

							echo -e "$STDCOLOR ------------------ $RESET"
							echo -e "$STDCOLOR Instalador de GLPI $RESET"
							echo -e "$STDCOLOR ------------------ $RESET"

							echo -e "$STDCOLOR De donde lo quieres instalar $RESET"
							declare -a web
							web=("172.31.0.5" "github")

							for i in ${!web[@]}; do
								echo -e "$i) ${web[$i]}"
							done

							read -p ">" webserver

							echo -e "$STDCOLOR Que nombre quieres para tu base de datos $RESET"
							read -p ">" database
							echo -e "$STDCOLOR Que nombre de usuario quieres para tu base de datos $RESET"
							read -p ">" username
							echo -e "$STDCOLOR Que contraseña quieres para tu base de datos $RESET"
							read -p ">" password

							echo -e "$STDCOLOR Instalando dependencias $RESET"
							apt update >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt install -y apache2 mariadb-server >>$LOGFILE 2>$ERRFILE
							test-err $?
							apt install -y php php-mysql php-intl php-zip php-xml php-curl php-gd php-mbstring unzip >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$STDCOLOR Instalando Prestashop $RESET"
							rm /var/www/html/index.html >>$LOGFILE 2>$ERRFILE
							case $webserver in
								0)
									wget http://172.31.0.5//prestashop/prestashop_1.7.7.2.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									mv prestashop_1.7.7.2.zip /var/www/html >>$LOGFILE 2>$ERRFILE
									test-err $?
									cd /var/www/html >>$LOGFILE 2>$ERRFILE
									test-err $?
									unzip prestashop_1.7.7.2.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									;;
								1)
									wget https://github.com/PrestaShop/PrestaShop/releases/download/8.0.4/prestashop_8.0.4.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									mv prestashop_8.0.4.zip /var/www/html >>$LOGFILE 2>$ERRFILE
									test-err $?
									cd /var/www/html >>$LOGFILE 2>$ERRFILE
									test-err $?
									unzip prestashop_8.0.4.zip >>$LOGFILE 2>$ERRFILE
									test-err $?
									;;
								*)
									echo "Respuesta incorrecta"
									break
									;;
							esac

							echo -e "$STDCOLOR Dando permisos $RESET"
							chown -R www-data:www-data /var/www/html/
							test-err $?

							echo -e "$STDCOLOR Creando base de datos $RESET"
							mysql -u root -e "create database $database;"
							test-err $?
							mysql -u root -e "create user '$username'@'localhost' identified by '$password';"
							test-err $?
							mysql -u root -e "grant all privileges on glpi.* to '$username'@'localhost';"
							test-err $?
							mysql -u root -e "flush privileges;"
							test-err $?

							echo -e "$STDCOLOR Reiniciando servidor web $RESET"
							a2enmod rewrite >>$LOGFILE 2>$ERRFILE
							test-err $?
							systemctl restart apache2 >>$LOGFILE 2>$ERRFILE
							test-err $?

							echo -e "$LYELLOW Abre tu Prestashop en el navegador $RESET"
							echo -e "$LGREY Base de datos: $database $RESET"
							echo -e "$LGREY Usuario: $username $RESET"
							echo -e "$LGREY Contraseña: $password $RESET"
							break 3
							;;

						# Para volver al menu anterior
						[Ee]|[Ee][Xx][Ii][Tt])
							break 2
							;;

						# Cualquier otra cosa
						*)
							echo "Respuesta incorrecta"
							break 2
							;;
					esac
				done
			done
			;;
		# Red
		1|[Rr]|[Rr][Ee][Dd])
			LOGFILE="/var/log/install/red.log"
			clear
			

			get_ip=$(ip a | grep "scope global dynamic" | tr -s " " | cut -d" " -f 3-3)
			get_gw=$(ip r | grep "default via" | tr -s " " | cut -d" " -f 3-3)
			get_dns=$(cat /etc/resolv.conf | grep "nameserver" | cut -d" " -f 2-2)

			echo -e "$LMAGENTA -------------------------------- $RESET"
			echo -e "$STDCOLOR  Tu IP es:$RESET \t ${get_ip}"
			echo -e "$STDCOLOR  Tu GW es:$RESET \t ${get_gw}"
			echo -e "$STDCOLOR  Tu DNS es:$RESET \t ${get_dns}"
			echo -e "$LMAGENTA -------------------------------- $RESET"
			echo -e "\n"

			ping -c 1 -W 1 google.com >>$LOGFILE 2>$ERRFILE
			test-ping $?

			echo -e "\n"
			echo -e "$LMAGENTA -------------------------------- $RESET"
			break
			;;
		# Hardware
		2|[Hh]|[Hh][Aa][Rr][Dd][Ww][Aa][Rr][Ee])
			LOGFILE="/var/log/install/hardware.log"
			clear
			

			apt install -y bc >>$LOGFILE 2>$ERRFILE

			if [ $LOCALE == es_ES.UTF-8 ]; then
				CPU_NAME=$(lscpu | grep "Nombre del modelo" | tr -s " " | cut -d" " -f4-)
			elif [ $LOCALE == en_UE.UTF-8 ]; then 
				CPU_NAME=$(lscpu | grep "Nombre del modelo" | tr -s " " | cut -d" " -f3-)
			fi

			CORES=$(lscpu | grep "Núcleo(s) por «socket»:" | tr -s " " | cut -d" " -f4-)
			THREADS=$(lscpu | grep "CPU(s):" | grep -v "NUMA" | tr -s " " | cut -d" " -f2-)
			RAM=$(dmidecode --type memory | grep "Size:" | grep -v "No" | grep -v "Volatile" | cut -d" " -f2 |  paste -sd+ | bc)
			RAM_TYPE=$(dmidecode --type memory | grep "Type:" | grep -v "Error" | grep -v "Unknown" | cut -d" " -f2 | uniq)
			VGA=$(lspci | grep "VGA" | cut -d" " -f5-)
			MOTHERBOARD=$(dmidecode --type system | grep "Product" | cut -d" " -f3-)

			echo -e "$LMAGENTA -----------------------------$RESET"
			echo -e "$STDCOLOR  Información sobre la CPU$RESET"
			echo -e "   Procesador:\t${CPU_NAME}"
			echo -e "   Nucleos:\t${CORES}"
			echo -e "   Hilos:\t${THREADS}"
			echo -e "$LMAGENTA -----------------------------$RESET"

			echo -e "$STDCOLOR  Información sobre la RAM$RESET"
			echo -e "   Cantidad:\t${RAM} GB"
			echo -e "   Tipo:\t${RAM_TYPE}"
			echo -e "$LMAGENTA -----------------------------$RESET"

			echo -e "$STDCOLOR  Información sobre la gráfica$RESET"
			echo -e "   Gráfica:\t${VGA}"
			echo -e "   Placa base:\t${MOTHERBOARD}"
			echo -e "$LMAGENTA -----------------------------$RESET"
			break
			;;

		# Para volver al menu anterior
		[Ee]|[Ee][Xx][Ii][Tt])
			echo -e "$ERRCOLOR Has salido con exito $RESET"
			break
			;;
		# Otra cosa
		*)
			echo "Respuesta incorrecta"
			;;
	esac
done
