port={{mysql_port}}
container_name=(`docker ps | awk '{print $NF}' | sed 1d | sort`)

check_mysql_port() {
   netstat -tlpn | grep "\b$port\b" &>/dev/null
}

if [ $container_name == "mysql{{mysql_version}}" ];then
   echo $port
   exit 0
fi

if check_mysql_port ! $port;then
   echo $port
   exit 0
fi

while [[ -n $new_port ]]  
do
   new_port=`ss -ntlp |grep $port |awk '{print $4}' |awk '{print substr($0,length($0)-3)}'`
   port=`expr $port + 1`
done
   echo $new_port
   exit 0
