#!/bin/bash
echo -e "Begin execution, Just a moment \n"
sudo systemctl stop mysql;
sudo sed -i 's/validate_password/#&/' /etc/my.cnf;
sudo sed -i '/\[mysqld\]/a skip-grant-tables'   /etc/my.cnf;
sudo systemctl start mysql
mysql_root_password=$(pwgen -ncCs 15 1)
version=$(mysql --version)
flag=0;
if [[  $version =~ "8.0" ]]
then
	mysql -u root mysql << EOF
	update user set authentication_string='' where user='root';
	update user set host='localhost' where user='root';
	flush privileges;
	ALTER user 'root'@'localhost' IDENTIFIED BY '$mysql_root_password';
	update user set host='%' where user='root';
	flush privileges;
EOF
	flag=1;
elif [[ $version =~ "10.4"  ]]
then
	/usr/bin/mysql -u root mysql << EOF
	flush privileges;
	SET password for 'root'@'%'=password('$mysql_root_password');
	flush privileges;
EOF
	flag=1;
elif [[ $version =~ "5.5" ]] || [[ $(mysql --version) =~ "5.6" ]] || [[ $(mysql --version) =~ "10.1" ]]
then
	/usr/bin/mysql -u root mysql << EOF
	update user set password = Password('$mysql_root_password') where User = 'root';
EOF
	flag=1;
elif [[ $version =~ "5.7" ]] || [[ $(mysql --version) =~ "10.2" ]] || [[ $(mysql --version) =~ "10.3" ]]
then
	/usr/bin/mysql -u root mysql << EOF
	update user set authentication_string = Password('$mysql_root_password') where User = 'root';
EOF
	flag=1;
fi
sudo sed -i 's/skip-grant-tables/#&/' /etc/my.cnf
sudo sed -i 's/#validate_password/validate_password/' /etc/my.cnf
sudo systemctl restart mysql
if [[ $flag == 1 ]]
then
	echo -e "Reset password success！\n"
	
	if [[ -s "/credentials/password.txt" ]]
	then
		sudo sed -i 's@mysql administrator password:.*@mysql administrator password: '$mysql_root_password'@g' /credentials/password.txt
	else
		echo -e "mysql administrator username:root
mysql administrator password:$mysql_root_password\n\n\n\n" >  /credentials/password.txt
	fi
	
	echo -e "The password of the newly set mysql root account is saved in the /credentials/password.txt directory, and the new password can be viewed through \`cat /credentials/password.txt\`\n"
	echo -e "The password of the newly set mysql root account is $mysql_root_password"
else
	echo "execute failed! "
	echo "It may be that your version is not within the version we support.  "
	echo -e "Password reset support version：mysql 5.5,mysql 5.6,mysql 5.7,mysql 8.0,mariadb 10.1,mariadb 10.2,mariadb 10.3,mariadb 10.4\n"
	echo "your version is $version"
fi
