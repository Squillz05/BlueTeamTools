5‑MINUTE PLAN — UBUNTU LINUX BOX (BEGINNER‑FRIENDLY, SAFE, DEFENSIVE)

1. Identify system + running services
   These commands show you what the machine is and what is running:
   hostnamectl
   who
   ss -tulpn
   systemctl list-units --type=service

2. Lock down SSH access (defensive only)
   Open the SSH config file:
   sudo nano /etc/ssh/sshd_config

   Look for these lines and set them:
   PermitRootLogin no
   PasswordAuthentication yes   (keep this ON if you are a beginner and using passwords)

   SAVE the file:
   Press CTRL+O, then ENTER, then CTRL+X

   Restart SSH safely:
   sudo systemctl restart ssh

   To confirm SSH is still running:
   sudo systemctl status ssh

3. Review users and sudo access
   View all users:
   cat /etc/passwd

   View sudoers:
   sudo cat /etc/sudoers
   ls -l /etc/sudoers.d/

   If you see a user you don’t recognize, you can lock them:
   sudo passwd -l <username>

4. Apply basic firewall rules
   Enable firewall:
   sudo ufw enable

   Allow only the ports you need:
   sudo ufw allow 22
   sudo ufw allow 80
   sudo ufw allow 443

   Deny everything else:
   sudo ufw default deny incoming

   Check firewall:
   sudo ufw status

5. Check for persistence mechanisms
   Cron jobs:
   crontab -l
   sudo ls /etc/cron.*

   Systemd services:
   sudo ls /etc/systemd/system/

   If you see something suspicious, disable it:
   sudo systemctl disable <service>

---------------------------------------------------------------------

5‑MINUTE PLAN — REDIS SERVER (BEGINNER‑FRIENDLY)

1. Confirm Redis is running and local-only
   sudo systemctl status redis
   ss -tulpn | grep 6379

2. Check Redis configuration
   Open config:
   sudo nano /etc/redis/redis.conf

   Ensure these lines exist:
   bind 127.0.0.1
   protected-mode yes

3. Set a password (safe, defensive)
   In redis.conf, find:
   # requirepass foobared

   Remove the # and change it to:
   requirepass StrongPasswordHere

4. Check file permissions
   sudo ls -ld /var/lib/redis
   sudo ls -l /etc/redis/redis.conf

   They should be owned by redis:redis

5. Restart Redis safely
   sudo systemctl restart redis
   sudo systemctl status redis

---------------------------------------------------------------------

5‑MINUTE PLAN — DATABASE SERVER (MYSQL/MARIADB BOX WE OWN)

1. Confirm service status
   sudo systemctl status mysql
   ss -tulpn | grep 3306

2. Check MySQL configuration
   sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf

   Ensure:
   bind-address = 127.0.0.1

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

5‑MINUTE PLAN — LAMP STACK ON UBUNTU BOX (APACHE + PHP + MYSQL)

1. Check Apache status
   sudo systemctl status apache2
   apache2ctl -S

2. Review Apache configuration
   sudo nano /etc/apache2/apache2.conf

   Inside any <Directory> blocks, ensure:
   Options -Indexes

   Check virtual hosts:
   sudo ls /etc/apache2/sites-enabled/

3. Review PHP configuration
   sudo nano /etc/php/*/apache2/php.ini

   Set:
   display_errors = Off
   expose_php = Off

4. Check MySQL local access only
   sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf
   Ensure:
   bind-address = 127.0.0.1

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
   sudo ufw default deny incoming

---------------------------------------------------------------------
