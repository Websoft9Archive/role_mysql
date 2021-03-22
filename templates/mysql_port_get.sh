mysql_port=3000
container_name=($(docker ps | awk '{print $NF}' | sed 1d |sort))

until [ -n "$mysql_new_port" ] 
do
 if [[ "${container_name[@]}" =~ "mysql{{mysql_port}}" ]]; then
   mysql_port=$(docker inspect mysql{{mysql_port}} |jq .[].NetworkSettings.Ports |grep HostPort |cut -d'"' -f4)
   echo $mysql_port
   exit 0
 else
   i=1
   mysql_new_port=`ss -ntlp |grep $mysql_port |awk '{print $4}' |awk '{print substr($0,length($0)-3)}'`
   mysql_port=`expr $mysql_port + 1`
 fi
   let i++
done

mysql_new_port=`expr $mysql_new_port + $i`
echo $mysql_new_port


