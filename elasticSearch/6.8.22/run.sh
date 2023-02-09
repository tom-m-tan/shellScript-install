#!/bin/bash
# author: ming.tan
# date: 2023.2.2
BootStart="/lib/systemd/system"
RunUser="sie-elastic"
RunGroup="sie-serivces"
SysConf=$(grep "vm.max_map_count=262144" /etc/sysctl.conf | wc -l)
EvnPath="/etc/profile.d"
elasticVersion=6.8.22
downurl="https://gushen-ecp.obs.cn-south-1.myhuaweicloud.com/elasticsearch/elasticsearch-6.8.22.tar.gz"
port=9200
params=$*
#判断是否有sie组
grep "^$RunGroup" /etc/group &>/dev/null
if [ $? -gt 0 ];then
    echo "没有所需${RunGroup}组,.请执行initHost脚本执行主机检查,创建该组..."
    exit 1
fi

id ${RunUser} || useradd -g ${RunGroup} ${RunUser}

dir=$(cd "$(dirname "$0")";pwd)

params=$*

getparamValue(){
  re=$(echo $params | awk -F "--$1=" '{print $2}' | awk '{print $1}')
  echo $re
}

checkparamValue(){
  if [ "$2" = "" ]; then
    echo "错误:参数 --$1 的值不能为空,程序将退出"
    exit
  fi
}

if [ $# -lt 2 ]; then
echo "当前脚本用于部署Elastic
=====================================================
参数表如下:
----------------------------------------------------
--rootdir          选填参数,组件安装目录定义,默认/sie/elastic
--packagedir       选填参数,备份目录,默认/sie/packagedir
--logdir           选填参数,日志目录,默认/sie/elastic/logs
--datadir          选填参数,数据目录,默认/sie/elastic/data
--backdir          选填参数,备份目录,默认/sie/backup/elasticback
--javahome         *{JAVAHOME}所在目录
--host             *服务IP,例如: 192.168.1.10;本机IP
--port             选填参数,默认端口9200
=====================================================
"
exit
fi

rootdir=$(getparamValue rootdir)

packagedir=$(getparamValue rootdir) 

datadir=$(getparamValue datadir)

logdir=$(getparamValue logdir)

backdir=$(getparamValue backdir)

port=$(getparamValue port)



host=$(getparamValue host)
checkparamValue host $host

javahome=$(getparamValue javahome)
checkparamValue javahome $javahome

if [ "${port}" = "" ]
then
    port=9200
fi

if [ "${rootdir}" = "" ]
then
    rootdir=/sie/elastic
fi

if [ "${packagedir}" = "" ]
then
    packagedir=/sie/packagedir
fi

if [ "${logdir}" = "" ]
then
    logdir=/sie/elastic/logs
fi

if [ "${datadir}" = "" ]
then
    datadir=/sie/elastic/data
fi

if [ "${backdir}" = "" ]
then
    backdir=/sie/backup/elasticback
fi

check_port() {
        netstat -tlpn | grep "\b$1\b"
}
if check_port $port
then
    echo "${port}端口存在,需更换"
    exit 1
else
    echo "  ${port}端口可用"
fi

if [ ! -d ${rootdir} ]
then
    mkdir -p ${rootdir}
    chown -R ${RunUser}:${RunGroup} ${rootdir}
    mkdir -p ${datadir}
    chown -R ${RunUser}:${RunGroup} ${datadir}
else
    echo "安装目录: rootdir:${rootdir}目录已存在,请检查是否有数据,程序将自动退出!"
    exit 9
fi

if [ ! -d ${backdir} ]
then
    mkdir -p ${backdir}
    chown -R ${RunUser}:${RunGroup} ${backdir}
else
    echo "备份目录: backdir:${backdir}目录已存在,请检查是否有数据,程序将自动退出!"
    exit 9
fi
# 下载
if [[ ! -f "${packagedir}/elasticsearch-${elasticVersion}.tar.gz" ]]; then
  echo "检索安装包ing,请稍后....."
  mkdir -p ${packagedir}
  wget -c -P ${packagedir} ${downurl} 
  else
  echo '安装包存在......'
  echo '======================================================='
  echo '正在解压安装......'
fi
# 解压安装
tar -xf ${packagedir}/elasticsearch-${elasticVersion}.tar.gz  -C ${rootdir}
chown -R ${RunUser}:${RunGroup} ${rootdir}/*
mkdir -p ${logdir}
chown -R ${RunUser}:${RunGroup} ${logdir}

if [ "${SysConf}" == 0 ];then
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf && sysctl -p > /dev/null
fi

cat>${rootdir}/elasticsearch-${elasticVersion}/config/elasticsearch.yml <<EOF
cluster.name: elasticsearch
node.name: node1
network.bind_host: 0.0.0.0
network.publish_host: ${host}
http.port: ${port}
transport.tcp.port: 9300
path.data: ${datadir}
path.logs: ${logdir}
bootstrap.memory_lock: false
bootstrap.system_call_filter: false
discovery.zen.ping_timeout: 300s
discovery.zen.fd.ping_retries: 10
client.transport.ping_timeout: 60s
discovery.zen.minimum_master_nodes: 2
http.max_content_length: 2000mb
http.max_header_size: 1024k
http.max_initial_line_length: 1024k
http.cors.enabled: true
http.cors.allow-origin: "*"
node.master: true
node.data: true
discovery.zen.ping.unicast.hosts:  "${host}:${port}"

EOF

cat>${EvnPath}/java.sh <<EOF
export JAVA_HOME=${javahome}
export PATH=\$PATH:\${JAVA_HOME}/bin
EOF

cat>${BootStart}/elasticsearch.service <<EOF
[Unit]
Description=Elasticsearch
[Service]
Type=forking
Environment=JAVA_HOME=${javahome}
User=${RunUser}
Group=${RunGroup}
LimitNOFILE=100000
LimitNPROC=100000
ExecStart=${rootdir}/elasticsearch-${elasticVersion}/bin/elasticsearch -d
[Install]
WantedBy=multi-user.target
EOF

systemctl  daemon-reload && systemctl start elasticsearch && systemctl  enable  elasticsearch

sleep 20s

ElasticPID=$(systemctl status elasticsearch | grep "Main PID" | awk -F ":" '{print$2}' | awk '{print$1}')
psWC=$(ps -ef | grep "$ElasticPID" | wc -l)
if [ "${psWC}" -gt 1 ];then
    echo '======================================================='
    echo '======================================================='
    echo 'elasticsearch 安装成功！！！'
    echo "elasticsearch服务所安装地址为: ${host}:${port}"
    echo "rootdir组件安装目录为: ${rootdir}"
    echo "datadir数据目录为: ${datadir} "
    echo "backdir备份目录为: ${backdir}"
    echo "JAVA安装目录为: ${javahome}"
    echo '======================================================='
    echo '======================================================='
    systemctl status elasticsearch
    exit 0
else
    echo '======================================================='
    echo '======================================================='
    echo '安装失败,请看系统状态日志！！！'
    echo '======================================================='
    echo '======================================================='
    systemctl status elasticsearch
fi