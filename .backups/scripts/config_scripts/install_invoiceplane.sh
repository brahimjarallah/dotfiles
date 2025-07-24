#!/bin/bash
set -e

#echo "==> Mise à jour du système"
#sudo pacman -Syu --noconfirm

echo "==> Installation des paquets PHP et MariaDB nécessaires"
sudo pacman -S --noconfirm php php-fpm php-gd php-intl php-curl php-xml php-zip mariadb nginx git

echo "==> Activation et démarrage de MariaDB"
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
sudo systemctl enable --now mariadb

echo "==> Création de la base de données et utilisateur InvoicePlane"
mysql -u root <<EOF
CREATE DATABASE invoicelane;
CREATE USER 'invoiceuser'@'localhost' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON invoicelane.* TO 'invoiceuser'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "==> Configuration PHP : activer mysqli"
sudo sed -i 's/;extension=mysqli/extension=mysqli/' /etc/php/php.ini

echo "==> Activation et démarrage de php-fpm et nginx"
sudo systemctl enable --now php-fpm nginx

echo "==> Installation d'InvoicePlane (ou Invoicelane) dans /usr/share/webapps"
sudo git clone https://github.com/InvoicePlane/InvoicePlane.git /usr/share/webapps/invoiceplane
sudo chown -R http:http /usr/share/webapps/invoiceplane

echo "==> Configuration Nginx pour InvoicePlane"
sudo tee /etc/nginx/conf.d/invoiceplane.conf > /dev/null <<EOF
server {
    listen 80;
    server_name localhost;

    root /usr/share/webapps/invoiceplane;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi.conf;
        fastcgi_pass unix:/run/php-fpm/php-fpm.sock;
    }
}
EOF

echo "==> Redémarrage de nginx"
sudo systemctl restart nginx

echo "==> Installation terminée !"
echo "Ouvre http://localhost dans ton navigateur pour finaliser la configuration InvoicePlane."

