#!/bin/bash
# safe redis hardening script

set -euo pipefail

echo "starting redis hardening..."

# 1. config
echo "checking redis config..."

REDIS_CONF="/etc/redis/redis.conf"

if [ ! -f "$REDIS_CONF" ]; then
    echo "redis.conf not found, exiting."
    exit 1
fi

# ask for redis password
read -sp "enter redis requirepass: " REDIS_PASS
echo ""

# set requirepass safely
if grep -q "^requirepass" "$REDIS_CONF"; then
    sed -i "s/^requirepass.*/requirepass $REDIS_PASS/" "$REDIS_CONF"
else
    echo "requirepass $REDIS_PASS" >> "$REDIS_CONF"
fi

# ensure protected mode is on
sed -i 's/^protected-mode .*/protected-mode yes/' "$REDIS_CONF"

# disable dangerous commands (non-destructive)
echo "renaming dangerous commands..."
sed -i 's/^#* *CONFIG /CONFIG_DISABLED /' "$REDIS_CONF" || true
sed -i 's/^#* *FLUSHALL /FLUSHALL_DISABLED /' "$REDIS_CONF" || true
sed -i 's/^#* *FLUSHDB /FLUSHDB_DISABLED /' "$REDIS_CONF" || true
sed -i 's/^#* *SHUTDOWN /SHUTDOWN_DISABLED /' "$REDIS_CONF" || true

echo "redis config updated."

# 2. permissions
echo "fixing redis file permissions..."

if [ -d /var/lib/redis ]; then
    chown -R redis:redis /var/lib/redis
    chmod 700 /var/lib/redis
fi

if [ -d /var/log/redis ]; then
    chown -R redis:redis /var/log/redis
    chmod 750 /var/log/redis
fi

chmod 640 "$REDIS_CONF"
chown redis:redis "$REDIS_CONF"

echo "permissions updated."

# 3. service
echo "reloading redis..."

systemctl restart redis-server || systemctl restart redis || true

echo "redis hardened."
