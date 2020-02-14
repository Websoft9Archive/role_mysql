#!/bin/bash
systemctl stop mysqld
mysqld --console --skip-grant-tables  --user=mysql &
sleep 5
{% if mysql_version <= "5.6" %}
mysql -e "use mysql;update user set password=password('') where user='root';"
{% endif %}
{% if mysql_version == "5.7" %}
mysql -e "use mysql;update user set authentication_string = password('') where user = 'root';"
{% endif %}
{% if mysql_version == "8.0" %}
mysql -e "use mysql;update user set authentication_string = '' where user = 'root';"
{% endif %}
ps aux | grep "mysqld" |grep -v grep| cut -c 9-15 | xargs kill -9
systemctl restart mysqld
