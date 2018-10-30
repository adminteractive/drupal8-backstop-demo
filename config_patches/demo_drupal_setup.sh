#!/bin/bash

apt-get update
apt-get install -y nodejs npm apache2 git mysql-server php7.2-fpm php7.2-mysql php7.2-xml php7.2-gd chromium-browser
a2enmod proxy_fcgi setenvif rewrite
a2enconf php7.2-fpm
systemctl reload apache2

mysql -u root << EOF
CREATE USER 'drupal'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'drupal'@'localhost';
FLUSH PRIVILEGES;
EOF

php -r "readfile('https://github.com/drush-ops/drush/releases/download/8.1.17/drush.phar');" > /usr/bin/drush
chmod +x /usr/bin/drush

rm /var/www/html/index.html
cd /var/www/html && git clone https://github.com/adminteractive/drupal8-backstop-demo.git .
cd /var/www/html && patch -b -p0 drupal/sites/default/settings.php < config_patches/settings.patch
cd /var/www/html && patch -b -p0 /etc/apache2/apache2.conf < config_patches/apache2.patch
service apache2 reload
cd /var/www/html/drupal && drush sql-create -y

cd /var/www/html/drupal && zcat sqldump.sql.gz |drush sql-cli
chown www-data -R /var/www/html/drupal/

npm i -g backstopjs back backstop-crawl