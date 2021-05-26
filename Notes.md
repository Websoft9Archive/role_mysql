### Package Install

官方提供两种安装方式：

* apt/yum 仓库在线安装
* deb/rpm 包下载安装

首选仓库安装，如果仓库地址无法安装所需的版本，则通过[下载 archives ](https://downloads.mysql.com/archives/community/)来安装。

举例：Ubuntu 20.04 仓库中没有提供 MySQL5.6 安装选项，怎么办？

![image](https://user-images.githubusercontent.com/16741975/119587334-0dc21500-be01-11eb-8c56-9c96cdf1210d.png)

下载选项中的 **Debian Linux** 和 **Linux Generic** 都可以使用，后者是 Linux  通用版本。

### mysql5.7 default my.cnf

### min install : [mysqld],[client]

```
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/5.7/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove leading # to turn on a very important data integrity option: logging
# changes to the binary log between backups.
# log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M
datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
validate_password=OFF

```
### create user default privellage 
USAGE => ALL ?

## Docker install MySQL

### volumes path edit
- /data/db/mysql5.7/my.cnf:/ect/my.cnf => - /data/db/mysql5.7/my.cnf:/etc/mysql/conf.d/my.cnf 

