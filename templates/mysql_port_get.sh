mysql_port=3306
container_name=($(docker ps | awk '{print $NF}' | sed 1d |sort))
mysql_container_number=$(docker ps |grep mysql |wc -l)

until [ -n "$mysql_new_port" ] 
do
 if [[ $mysql_container_number -eq 0 ]]; then
   echo {{mysql_port}}
   exit 0
 elif [[ "${container_name[@]}" =~ "mysql{{mysql_version}}" ]]; then
   mysql_port=$(docker inspect mysql{{mysql_version}} |jq .[].NetworkSettings.Ports |grep HostPort |cut -d'"' -f4)
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


