#!/bin/bash
systemctl stop mysqld
mysqld --console --skip-grant-tables  --user=mysql &
{% if mysql_version <= "5.6" %}
mysql -e "use mysql;update user set password=password('{{mysql_root_password}}') where user='root';"
ps aux | grep "mysqld" |grep -v grep| cut -c 9-15 | xargs kill -9
{% endif %}
{% if mysql_version == "7.0" %}
mysql -e "use mysql;update user set authentication_string = password('{{mysql_root_password}}') where user = 'root';"
ps aux | grep "mysqld" |grep -v grep| cut -c 9-15 | xargs kill -9
{% endif %}
{% if mysql_version == "8.0" %}
mysql -e "use mysql;update user set authentication_string = '' where user = 'root';"
ps aux | grep "mysqld" |grep -v grep| cut -c 9-15 | xargs kill -9
systemctl start mysqld
mysql -uroot --password='' -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '{{mysql_root_password}}'" --connect-expired-password
{% endif %}
systemctl restart mysqld
