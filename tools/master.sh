#!/bin/bash

## if error, exit
set -o errexit   #遇见报错退出

help_str="
  -h, --help      show help information
  -M, --master-root-password  master mysql root password, Required parameter
  -u, --slave-username   slave mysql username, Required parameter
  -s, --slave-password   slave mysql password, Required parameter
  example:
    bash master.sh -M "123456" -u "slave" -s "123456"
"

master_mysql_root_password=""
slave_mysql_username=""
slave_mysql_password=""

## get parameters
getopt_cmd=$(getopt -o hM:u:s:  --long help,master-root-password:,slave-username:,slave-password: -n "Parameters error" -- "$@")   
eval set --"$getopt_cmd"  #等同于导入列表，输出为 -M "123456" -u "slave" -s "123456"，也就是命令后的参数

while [ -n "$1" ]
do
	case "$1" in
      -M|--master-root-password)
        master_mysql_root_password=$2;
        sudo echo "master mysql root password is: $master_mysql_root_password"
        shift 2;;  #输出完左移两位
      -u|--slave-username)
        slave_mysql_username=$2;
        sudo echo "slave mysql username is: $slave_mysql_username"
        shift 2;;
      -s|--slave-password)
        slave_mysql_password=$2;
        sudo echo "slave mysql password is: $slave_mysql_password"
        shift 2;;
      -h|--help)
        sudo echo -e "$help_str"
        break ;;
      --)
        break ;;
      *)
        sudo echo "$help_str"
        break ;;
	esac
done

[ ! $master_mysql_root_password ]  && exit 3  #存在变量时则不退出
[ ! $slave_mysql_username ] && exit 3
[ ! $slave_mysql_password ]  && exit 3
sudo echo "Get parameters success !"

## update mysql configure
config_list=(
bind-address
server-id
server_id
log_bin
)

mysql_config_file="/etc/my.cnf"

if [ -f "$mysql_config_file" ];then
        for str in ${config_list[@]};do
                sudo sed -i "/$str/d" $mysql_config_file
        done
        sudo sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' $mysql_config_file
        sudo sed -i '/\[mysqld\]/a server-id = 1' $mysql_config_file
        sudo sed -i '/\[mysqld\]/a log_bin = /var/lib/mysql/mysql-bin.log' $mysql_config_file
        sudo systemctl restart mysqld  
        sudo echo "mysql config file update success !"
else
   sudo echo "MySql config file not found"
   exit 2
fi

## Change slave uuid 
## master and slave uuid needs  to be the same

## cat > /var/lib/mysql/auto.cnf <<EOF
## [auto]
## server-uuid=f2d0efd6-6ab7-11e8-8fdd-fa163eda7360
## EOF

## check user exists
usertest="SELECT EXISTS(SELECT 1 FROM mysql.user WHERE user = '$slave_mysql_username')"
msg=$(mysql -uroot -p"$master_mysql_root_password" -e "${usertest}" |sed -n 2p)

if [ "$msg" = 1 ];then
mysql -uroot -p"$master_mysql_root_password" <<EOF
drop user $slave_mysql_username@'%'
EOF
fi

## create slave user and set all permissive 
mysql -uroot -p"$master_mysql_root_password" <<EOF
CREATE USER '$slave_mysql_username'@'%' IDENTIFIED BY '$slave_mysql_password';
GRANT ALL PRIVILEGES ON *.* TO '$slave_mysql_username'@'%';
EOF
sudo echo "Create mysql user and set permissive success !"

sudo echo "flush privileges" | mysql -uroot -p"$master_mysql_root_password"

master_log_file=`mysql -uroot -p"$master_mysql_root_password" -e "SHOW MASTER STATUS;" |grep mysql-bin | awk '{print $1}'`
master_log_pos=`mysql -uroot -p"$master_mysql_root_password" -e "SHOW MASTER STATUS;" |grep mysql-bin | awk '{print $2}'`

sudo echo "master log file is: $master_log_file"
sudo echo "master log pos is: $master_log_pos"

sudo echo "--------------------------------------------"
sudo echo "Congratulations, run complete."
sudo echo "--------------------------------------------"
