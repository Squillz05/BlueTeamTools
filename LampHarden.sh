#!/bin/bash
# safe LAMP hardening script

set -euo pipefail

echo "starting LAMP hardening..."

# 1. apache
echo "hardening apache..."

# disable directory listing
if ! grep -q "Options -Indexes" /etc/apache2/apache2.conf; then
    echo "Options -Indexes" >> /etc/apache2/apache2.conf
fi

# hide version info
a2dismod -f autoindex >/dev/null 2>&1 || true
sed -i 's/^ServerTokens.*/ServerTokens Prod/' /etc/apache2/conf-available/security.conf
sed -i 's/^ServerSignature.*/ServerSignature Off/' /etc/apache2/conf-available/security.conf

# enable useful modules
a2enmod headers >/dev/null 2>&1 || true
a2enmod rewrite >/dev/null 2>&1 || true

# add basic security headers
SEC_FILE="/etc/apache2/conf-available/security-headers.conf"
if [ ! -f "$SEC_FILE" ]; then
cat <<EOF > "$SEC_FILE"
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set X-Content-Type-Options "nosniff"
</IfModule>
EOF
    a2enconf security-headers >/dev/null 2>&1 || true
fi

apache2ctl configtest && systemctl reload apache2
echo "apache hardened."

# 2. php

echo "hardening php..."

PHPINI=$(php -i 2>/dev/null | grep "Loaded Configuration" | awk '{print $5}')

if [ -f "$PHPINI" ]; then
    sed -i 's/^expose_php.*/expose_php = Off/' "$PHPINI"
    sed -i 's/^display_errors.*/display_errors = Off/' "$PHPINI"
    sed -i 's/^allow_url_fopen.*/allow_url_fopen = Off/' "$PHPINI"
    sed -i 's/^allow_url_include.*/allow_url_include = Off/' "$PHPINI"
    sed -i 's/^session.cookie_httponly.*/session.cookie_httponly = 1/' "$PHPINI"
    sed -i 's/^session.cookie_secure.*/session.cookie_secure = 1/' "$PHPINI"
    sed -i 's/^session.use_strict_mode.*/session.use_strict_mode = 1/' "$PHPINI"
fi

systemctl reload apache2
echo "php hardened."

# 3. mysql
echo "hardening mysql..."

mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root' AND Host!='localhost';" 2>/dev/null || true
mysql -e "DELETE FROM mysql.user WHERE User='';" 2>/dev/null || true
mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

echo "mysql hardened."

# 4. permissions
echo "fixing web root permissions..."

if [ -d /var/www ]; then
    chown -R root:root /var/www
    find /var/www -type d -exec chmod 755 {} \;
    find /var/www -type f -exec chmod 644 {} \;
fi

echo "permissions updated."

# 5. logs
echo "securing apache logs..."

chmod 750 /var/log/apache2 || true

echo "LAMP hardening complete."
