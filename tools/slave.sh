#!/bin/bash

## if error, exit
set -o errexit

help_str="
  -h, --help      show help information
  -i, --id        slave server id, Required parameters
  -H, --host      master host ip, Required parameters
  -u, --slave-username   slave mysql username, Required parameter
  -s, --slave-password   slave mysql password, Required parameter
  -S, --slave-root-password   slave mysql root password, Required parameter
  -f, --master-logfile   master binlog logs filename, Required parameter, obtain the value from the master.sh result
  -p, --master-logpos    master binlog logs pos value, obtain the value from the master.sh result
  example:
    bash slave.sh -i 2 -H "192.168.0.1" -u "slave" -s "123456" -S "123456" -f "mysql-bin.000001" -p 214
"

slave_server_id=""
master_local_host=""
slave_mysql_root_password=""
slave_mysql_username=""
slave_mysql_password=""
master_log_file=""
master_log_pos=""

## get parameters
getopt_cmd=$(getopt -o hi:H:u:s:S:f:p: --long help,id:,host:,slave-username:,slave-password:,slave-root-password:,master-logfile:,master-logpos: -n "Parameters error" -- "$@")
eval set --"$getopt_cmd"

while [ -n "$1" ]
do
	case "$1" in
      -i|--id)
        slave_server_id=$2;
        sudo echo "slave slave server id is: $slave_server_id"
        shift 2;;
      -H|--host)
        master_local_host=$2;
        sudo echo "master local host is: $master_local_host"
        shift 2;;
      -u|--slave-username)
        slave_mysql_username=$2;
        sudo echo "slave mysql username is: $slave_mysql_username"
        shift 2;;
      -s|--slave-password)
        slave_mysql_password=$2;
        sudo echo "slave mysql password is: $slave_mysql_password"
        shift 2;;
      -S|--slave-root-password)
        slave_mysql_root_password=$2;
        sudo echo "slave mysql root password is: $slave_mysql_root_password"
        shift 2;;
      -f|--master-logfile)
        master_log_file=$2;
        sudo echo "master log file is: $master_log_file"
        shift 2;;
      -p|--master-pos)
        master_log_pos=$2;
        sudo echo "master log pos is: $master_log_pos"
        shift 2;;
      -h|--help)
        sudo echo -e "$help_str"
        break ;;
      --)
        break ;;
      *)
        echo "$help_str"
        break ;;
	esac
done

[ ! $slave_server_id ] && exit 3
[ ! $master_local_host ] && exit 3
[ ! $slave_mysql_username ] && exit 3
[ ! $slave_mysql_password ] && exit 3
[ ! $slave_mysql_root_password ] && exit 3
[ ! $master_log_file ] && exit 3
[ ! $master_log_pos ] && exit 3
sudo echo "Get parameters success !"

## update mysql configure
config_list=(
bind-address
server-id
server_id
log_bin
)

## Change slave uuid 
## master and slave uuid needs  to be the same

## cat > /var/lib/mysql/auto.cnf <<EOF
## [auto]
## server-uuid=f2d0efd6-6ab7-11e8-8fdd-fa163eda7360
## EOF

mysql_config_file="/etc/my.cnf"

if [ -f "$mysql_config_file" ];then
	for str in ${config_list[@]};do
    sudo sed -i "/$str/d" $mysql_config_file
	done  
    sudo sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' $mysql_config_file
    sudo sed -i "/\[mysqld\]/a server-id = $slave_server_id" $mysql_config_file
    sudo sed -i '/\[mysqld\]/a log_bin = /var/lib/mysql/mysql-bin.log' $mysql_config_file
    sudo systemctl restart mysqld 
    sudo echo "MySql config file update success !" 
else
   sudo echo "MySql cofigure file not exist"
   exit 2
fi

## slave configure 
sql_slave_config="CHANGE MASTER TO MASTER_HOST='"$master_local_host"', MASTER_USER='"$slave_mysql_username"', MASTER_PASSWORD='"$slave_mysql_password"', MASTER_LOG_FILE='"$master_log_file"', MASTER_LOG_POS="$master_log_pos";"

sudo echo "STOP SLAVE;" | mysql -uroot -p"$slave_mysql_root_password"
sudo echo $sql_slave_config | mysql -uroot -p"$slave_mysql_root_password"
sudo echo "START SLAVE;" | mysql -uroot -p"$slave_mysql_root_password"
sudo echo "MySql configuration complete"

## check mysql master and slave state
io_state=`sudo echo "SHOW SLAVE STATUS\G;" | mysql -uroot -p"$slave_mysql_root_password" |grep Slave_IO_Running`
sql_state=`sudo echo "SHOW SLAVE STATUS\G;" | mysql -uroot -p"$slave_mysql_root_password" |grep Slave_SQL_Running`

sudo echo ${io_state}
sudo echo ${sql_state}

sudo echo "--------------------------------------------"
sudo echo "Congratulations, run complete."
sudo echo "--------------------------------------------"


