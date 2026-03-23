# BlueTeamTools (Rule-Compliant Edition)

SECTION 1 — REDIS DATABASE
Redis is an in-memory key-value store used for caching, sessions, and queues.

How to access Redis:
systemctl status redis
ps aux | grep redis
ss -tulpn | grep 6379
redis-cli
redis-cli -h <server-ip> -p 6379

Important Redis file locations:
Main config: /etc/redis/redis.conf
Data directory: /var/lib/redis/
RDB snapshot: /var/lib/redis/dump.rdb
AOF file: /var/lib/redis/appendonly.aof
Logs: /var/log/redis/redis-server.log
Systemd service: /lib/systemd/system/redis-server.service

What to check inside Redis:
Security settings in redis.conf:
# DO NOT bind to localhost on a scored service
# bind 127.0.0.1   (leave commented out)
protected-mode yes
requirepass <password>
# Do not rename commands unless you confirm scoring does not use them

Persistence settings:
dir
dbfilename
appendonly
appendfsync

Modules:
redis-cli MODULE LIST

Keys and data:
redis-cli INFO
redis-cli KEYS '*'
redis-cli TYPE <key>

Workflow to secure Redis (Rule-Compliant):
Edit /etc/redis/redis.conf
Ensure protected-mode yes
Set requirepass to a strong password
Do NOT change bind address (scoring engine must reach Redis)
Restart Redis: sudo systemctl restart redis
Firewall: block Red Team IPs only, never block 10.10.10.10 or 10.10.10.11

---------------------------------------------------------------------

SECTION 2 — LAMP STACK (LINUX, APACHE, MYSQL, PHP)

How to access Apache:
systemctl status apache2
apache2ctl -M
apache2ctl -S

How to access MySQL:
systemctl status mysql
mysql -u root -p

How to access PHP:
php -v
php -m
php --ini

Important Apache file locations:
Main config: /etc/apache2/apache2.conf
Virtual hosts: /etc/apache2/sites-enabled/
Modules: /etc/apache2/mods-enabled/
Document root: /var/www/html/
Logs: /var/log/apache2/

Important MySQL file locations:
Config: /etc/mysql/mysql.conf.d/mysqld.cnf
Databases: /var/lib/mysql/
Logs: /var/log/mysql/
User accounts stored in mysql.user table

Important PHP file locations:
php.ini: /etc/php/*/apache2/php.ini
FPM config: /etc/php/*/fpm/pool.d/
Modules: /etc/php/*/mods-available/

What to check in Apache:
Disable directory listing: Options -Indexes
Check for world-writable files: find /var/www -type f -perm -o+w
Remove dev files: .git, .env, phpinfo.php
Check virtual hosts: apache2ctl -S

What to check in MySQL:
# DO NOT bind to localhost on a scored service
# bind-address = 127.0.0.1 (leave default)
Remove anonymous users
Check user privileges:
SELECT user, host, authentication_string FROM mysql.user;

What to check in PHP:
Disable dangerous functions: exec, passthru, shell_exec,system
Turn off display_errors
Limit upload sizes
Disable remote file includes

Workflow to secure Apache:
Edit /etc/apache2/apache2.conf
Add or ensure: Options -Indexes
Check /etc/apache2/sites-enabled/ for misconfigurations
Remove leftover dev files in /var/www
Restart Apache: sudo systemctl restart apache2

Workflow to secure MySQL:
mysql -u root -p
Remove anonymous users
Set strong passwords
Do NOT change bind-address on scored services
Restart MySQL: sudo systemctl restart mysql

Workflow to secure PHP:
Edit php.ini
Set display_errors = Off
Set disable_functions = exec,passthru,shell_exec,system
Restart Apache or PHP-FPM depending on setup

---------------------------------------------------------------------

SECTION 3 — BLUE-UBNT-04 (UBUNTU SERVER)

How to access:
ssh <user>@blue-ubnt-04

Critical Linux locations to check:
System identity:
hostnamectl
cat /etc/os-release

Users and groups:
cat /etc/passwd
cat /etc/group
getent passwd

Sudoers:
cat /etc/sudoers
ls -l /etc/sudoers.d/

Services:
systemctl list-units --type=service
ss -tulpn

Cron jobs:
crontab -l
ls /etc/cron.*

Startup scripts:
ls /etc/systemd/system/
ls /lib/systemd/system/

Logs:
journalctl -xe
ls /var/log/

Workflow to secure the host:
Lock down SSH:
Edit /etc/ssh/sshd_config
Set PermitRootLogin no
Set PasswordAuthentication yes (authorized users must still log in)
Restart SSH: sudo systemctl restart ssh

Firewall:
sudo ufw enable
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow from 10.10.10.10
sudo ufw allow from 10.10.10.11
# Block Red Team IPs individually (allowed)
sudo ufw deny from <red-team-ip>

File permissions:
find / -type f -perm -o+w
find /var/www -type f -perm -o+w

Remove rogue users:
sudo deluser <name>

Check persistence:
Cron jobs
Systemd services
SUID binaries
SSH authorized_keys
Webshells in /var/www/

---------------------------------------------------------------------

SECTION 4 — HOW TO CHANGE PASSWORDS ON LINUX

Change your own password:
passwd

Change another user’s password:
sudo passwd <username>

Example:
sudo passwd blueteam

Lock a user account:
sudo passwd -l <username>

Unlock a user account:
sudo passwd -u <username>

Force password reset on next login:
sudo chage -d 0 <username>

---------------------------------------------------------------------
