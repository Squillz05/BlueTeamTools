5‑MINUTE PLAN — UBUNTU LINUX BOX (BEGINNER‑FRIENDLY, SAFE, RULE‑COMPLIANT)

1. Identify system + running services
   These commands show what the machine is and what is running:
   hostnamectl
   who
   ss -tulpn
   systemctl list-units --type=service

2. Lock down SSH access (defensive only, without breaking scoring)
   Open SSH config:
   sudo nano /etc/ssh/sshd_config

   Set:
   PermitRootLogin no
   PasswordAuthentication yes   (keep ON so authorized users can still log in)

   Save:
   CTRL+O, ENTER, CTRL+X

   Restart SSH safely:
   sudo systemctl restart ssh

   Confirm SSH is running:
   sudo systemctl status ssh

3. Review users and sudo access
   View all users:
   cat /etc/passwd

   View sudoers:
   sudo cat /etc/sudoers
   ls -l /etc/sudoers.d/

   Lock unknown accounts (do NOT lock authorized Amazonians):
   sudo passwd -l <username>

4. Apply firewall rules (must allow scoring IPs)
   Enable firewall:
   sudo ufw enable

   Allow required ports:
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443

   Whitelist scoring IPs:
   sudo ufw allow from 10.10.10.10
   sudo ufw allow from 10.10.10.11

   Default deny:
   sudo ufw default deny incoming

   Check:
   sudo ufw status

5. Check for persistence mechanisms
   Cron jobs:
   crontab -l
   sudo ls /etc/cron.*

   Systemd services:
   sudo ls /etc/systemd/system/

   Disable suspicious services:
   sudo systemctl disable <service>

---------------------------------------------------------------------

5‑MINUTE PLAN — REDIS SERVER (RULE‑COMPLIANT: DO NOT BIND TO LOCALHOST)

1. Confirm Redis is running
   sudo systemctl status redis
   ss -tulpn | grep 6379

2. Check Redis configuration
   sudo nano /etc/redis/redis.conf

   DO NOT set bind 127.0.0.1 (scoring engine must reach Redis)
   Ensure:
   protected-mode yes

3. Set a password (safe, allowed)
   Find:
   # requirepass foobared

   Change to:
   requirepass StrongPasswordHere

4. Check file permissions
   sudo ls -ld /var/lib/redis
   sudo ls -l /etc/redis/redis.conf

   Should be owned by redis:redis

5. Restart Redis safely
   sudo systemctl restart redis
   sudo systemctl status redis

---------------------------------------------------------------------

5‑MINUTE PLAN — DATABASE SERVER (MYSQL/MARIADB, RULE‑COMPLIANT)

1. Confirm service status
   sudo systemctl status mysql
   ss -tulpn | grep 3306

2. Check MySQL configuration
   sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

   DO NOT set bind-address to 127.0.0.1 (scoring engine must reach DB)
   Leave default or ensure it listens on the server’s assigned IP.

3. Log into MySQL
   sudo mysql -u root -p

4. Check users
   SELECT user, host FROM mysql.user;

   Remove anonymous users:
   DROP USER ''@'localhost';

   Set strong passwords:
   ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword';

5. Restart MySQL
   sudo systemctl restart mysql
   sudo systemctl status mysql

---------------------------------------------------------------------

5‑MINUTE PLAN — LAMP STACK ON UBUNTU BOX (APACHE + PHP + MYSQL, RULE‑COMPLIANT)

1. Check Apache status
   sudo systemctl status apache2
   apache2ctl -S

2. Review Apache configuration
   sudo nano /etc/apache2/apache2.conf

   Ensure:
   Options -Indexes

   Check virtual hosts:
   sudo ls /etc/apache2/sites-enabled/

3. Review PHP configuration
   sudo nano /etc/php/*/apache2/php.ini

   Set:
   display_errors = Off
   expose_php = Off

4. MySQL access (IMPORTANT)
   DO NOT bind MySQL to localhost on a scored service.
   Leave bind-address as default or set to server’s IP.

5. Restart services
   sudo systemctl restart apache2
   sudo systemctl restart mysql

---------------------------------------------------------------------

5‑MINUTE PLAN — LAMP STACK ON DEDICATED SERVER (WE OWN THE WHOLE BOX)

1. Confirm system identity + services
   hostnamectl
   systemctl list-units --type=service

2. Lock down Apache
   Disable unused modules:
   sudo a2dismod <module>

   Check logs:
   sudo tail -n 50 /var/log/apache2/error.log

3. Lock down PHP
   sudo nano /etc/php/*/apache2/php.ini
   Set:
   disable_functions = exec,passthru,shell_exec,system
   upload_max_filesize = 2M

4. Lock down MySQL
   sudo mysql_secure_installation

5. Host-level hardening
   sudo ufw enable
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443
   sudo ufw allow from 10.10.10.10
   sudo ufw allow from 10.10.10.11
   sudo ufw default deny incoming

---------------------------------------------------------------------
