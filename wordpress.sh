#!/bin/bash

# Comprobación de permisos de administrador
if [[ $EUID -ne 0 ]]; then
   echo "Este script debe ejecutarse como root" 
   exit 1
fi

# Variables personalizables
DB_NAME="DB"
DB_USER="admin"
DB_PASSWORD="admin"

# Actualización e instalación de paquetes necesarios
echo "Actualizando los repositorios y instalando los paquetes necesarios..."
apt-get update && apt-get install -y apache2 mariadb-server unzip php php-mysql 
if [[ $? -ne 0 ]]; then
    echo "Error en la instalación de paquetes. Revisa la conexión a Internet o los repositorios."
    exit 1
fi

# Configuración de base de datos y usuario
echo "Configurando la base de datos y el usuario de MySQL..."
mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

if [[ $? -ne 0 ]]; then
    echo "Error en la configuración de la base de datos o usuario de MySQL."
    exit 1
fi

# Instalación de WordPress
echo "Descargando y configurando WordPress..."
wget -q https://wordpress.org/latest.tar.gz -P /opt/
if [[ $? -ne 0 ]]; then
    echo "Error al descargar WordPress."
    exit 1
fi

# Extracción y configuración de WordPress
tar -zxvf /opt/latest.tar.gz -C /opt/ 
rm -f /var/www/html/index.html 
mv /opt/wordpress/* /var/www/html/ 
chown -R www-data:www-data /var/www/html/ 
chmod -R 755 /var/www/html 

# Reiniciar Apache para aplicar los cambios
echo "Reiniciando el servicio de Apache..."
systemctl restart apache2
if [[ $? -ne 0 ]]; then
    echo "Error al reiniciar Apache."
    exit 1
fi

# Mensaje final de confirmación
clear
echo -e "WordPress ha sido instalado correctamente.\nPuedes acceder desde el navegador en: http://localhost:80"
