#!/bin/bash
# competition-safe LAMP hardening script

set -euo pipefail

echo "starting LAMP hardening..."

# 1. apache
echo "hardening apache..."

APACHE_CONF="/etc/apache2/apache2.conf"
SEC_CONF="/etc/apache2/conf-available/security.conf"

# disable directory listing SAFELY (no duplicates)
if ! grep -q "Options -Indexes" "$APACHE_CONF"; then
    echo "<Directory /var/www/>" >> "$APACHE_CONF"
    echo "    Options -Indexes" >> "$APACHE_CONF"
    echo "</Directory>" >> "$APACHE_CONF"
fi

# hide version info (safe replace or append)
grep -q "^ServerTokens" "$SEC_CONF" && \
    sed -i 's/^ServerTokens.*/ServerTokens Prod/' "$SEC_CONF" || \
    echo "ServerTokens Prod" >> "$SEC_CONF"

grep -q "^ServerSignature" "$SEC_CONF" && \
    sed -i 's/^ServerSignature.*/ServerSignature Off/' "$SEC_CONF" || \
    echo "ServerSignature Off" >> "$SEC_CONF"

# enable useful modules (safe)
a2enmod headers >/dev/null 2>&1 || true
a2enmod rewrite >/dev/null 2>&1 || true

# add basic security headers (only if not exists)
SEC_FILE="/etc/apache2/conf-available/security-headers.conf"
if [ ! -f "$SEC_FILE" ]; then
cat <<EOF > "$SEC_FILE"
<IfModule mod_headers.c>
    Header always set X-Frame-Options "SAMEORIGIN"
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
    sed -i 's/^expose_php.*/expose_php = Off/' "$PHPINI" || true
    sed -i 's/^display_errors.*/display_errors = Off/' "$PHPINI" || true

    # ❌ removed allow_url_fopen change (can break apps)
    sed -i 's/^allow_url_include.*/allow_url_include = Off/' "$PHPINI" || true

    sed -i 's/^session.cookie_httponly.*/session.cookie_httponly = 1/' "$PHPINI" || true
    sed -i 's/^session.use_strict_mode.*/session.use_strict_mode = 1/' "$PHPINI" || true
fi

systemctl reload apache2
echo "php hardened."

# 3. mysql
echo "hardening mysql..."

# keep anonymous users (per your requirement)
mysql -e "UPDATE mysql.user SET Host='localhost' WHERE User='root' AND Host!='localhost';" 2>/dev/null || true
mysql -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
mysql -e "FLUSH PRIVILEGES;" 2>/dev/null || true

echo "mysql hardened."

# 4. permissions
echo "skipping /var/www ownership changes to avoid breaking apps..."

# 5. logs
echo "securing apache logs..."

chmod 750 /var/log/apache2 || true

echo "LAMP hardening complete."
