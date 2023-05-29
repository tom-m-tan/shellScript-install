#!/bin/bash
# author: ming.tan
# date: 2023.2.8
RunUser="sie-harbor"
RunGroup="sie-serivces"
harborVersion=v1.10.16
Harbordownurl="http://package.sieiot.com/harbor/harbor-offline-installer-v1.10.16.tgz"
Composedownurl="http://package.sieiot.com/harbor/docker-compose-linux-x86_64"
params=$*

#判断是否有sie组
grep "^$RunGroup" /etc/group &>/dev/null
if [ $? -gt 0 ]; then
  echo "没有所需${RunGroup}组,.请执行initHost脚本执行主机检查,创建该组..."
  exit 1
fi

id ${RunUser} || useradd -g ${RunGroup} ${RunUser}

dir=$(
  cd "$(dirname "$0")"
  pwd
)
params=$*

getparamValue() {
  re=$(echo $params | awk -F "--$1=" '{print $2}' | awk '{print $1}')
  echo $re
}

checkparamValue() {
  if [ "$2" = "" ]; then
    echo "错误:参数 --$1 的值不能为空,程序将退出"
    exit
  fi
}

if [ $# -lt 1 ]; then
  echo "当前脚本用于部署Harbor
=====================================================
参数表如下:
----------------------------------------------------
--rootdir          选填参数,组件安装目录定义,默认/sie/harbor
--packagedir       选填参数,备份目录,默认/sie/packagedir
--logdir           选填参数,日志目录,默认/sie/harbor/logs
--datadir          选填参数,数据目录,默认/sie/harbor/data
--backdir          选填参数,备份目录,默认/sie/backup/harborback
--host             *服务IP,例如: 192.168.1.10;本机IP
--port             选填参数,默认端口80
--harborpasswd     选填参数,harbor密码,默认密码:Harbor12345
--dbpasswd         选填参数,存储数据库密码,默认密码db@Admin123
=====================================================
"
  exit
fi

rootdir=$(getparamValue rootdir)

packagedir=$(getparamValue packagedir)

logdir=$(getparamValue logdir)

datadir=$(getparamValue datadir)

backdir=$(getparamValue backdir)

harborpasswd=$(getparamValue harborpasswd)

dbpasswd=$(getparamValue dbpasswd)

# 必填项
host=$(getparamValue host)
checkparamValue host $host

port=$(getparamValue port)

if [ "${port}" = "" ]; then
  port=80
fi

if [ "${rootdir}" = "" ]; then
  rootdir=/sie/harbor
fi

if [ "${packagedir}" = "" ]; then
  packagedir=/sie/packagedir
fi

if [ "${logdir}" = "" ]; then
  logdir=/sie/harbor/logs
fi

if [ "${datadir}" = "" ]; then
  datadir=/sie/harbor/data
fi

if [ "${backdir}" = "" ]; then
  backdir=/sie/backup/harborback
fi

if [ "${harborpasswd}" = "" ]; then
  harborpasswd=Harbor12345
fi

if [ "${dbpasswd}" = "" ]; then
  dbpasswd=db@Admin123
fi

check_port() {
  netstat -tlpn | grep "\b$1\b"
}
if check_port $port; then
  echo "${port}端口存在,需更换"
  exit 1
else
  echo "  ${port}端口可用"
fi

if [ ! -d ${rootdir} ]; then
  mkdir -p ${rootdir}
  chown -R ${RunUser}:${RunGroup} ${rootdir}
  mkdir -p ${datadir}
  chown -R ${RunUser}:${RunGroup} ${datadir}
else
  echo "安装目录: rootdir:${rootdir}目录已存在,请检查是否有数据,程序将自动退出!"
  exit 9
fi

if [ ! -d ${backdir}/harbor ]; then
  mkdir -p ${backdir}
  chown -R ${RunUser}:${RunGroup} ${backdir}
else
  echo "备份目录: backdir:${backdir}目录已存在,请检查是否有数据,程序将自动退出!"
  exit 9
fi

docker ps &>/dev/null
if [ $? -ne 0 ]; then
  echo 'docker未安装,请先安装docker,再执行该脚本。'
  exit 1
fi

chown -R ${RunUser}:${RunGroup} ${rootdir}

if [[ ! -f "${packagedir}/harbor-offline-installer-${harborVersion}.tgz" ]]; then
  echo "Harbor安装包不存在,下载中......"
  mkdir ${packagedir}
  wget -c -P ${packagedir} ${Harbordownurl}
else
  echo "harbor安装包存在......"
fi

tar -xf ${packagedir}/harbor-offline-installer-${harborVersion}.tgz -C ${rootdir}

if [[ ! -f "${packagedir}/docker-compose-linux-x86_64" ]]; then
  echo "docker-compose安装包不存在,下载中......"
  wget -c -P ${packagedir} ${Composedownurl}
else
  echo "compose安装包存在......"
fi

cp ${packagedir}/docker-compose-linux-x86_64 ${rootdir}/harbor/docker-compose-linux-x86_64
chmod -R 777 ${rootdir}/harbor/docker-compose-linux-x86_64

if [ -f /usr/bin/docker-compose ]; then
  rm -rf /usr/bin/docker-compose
fi
ln -s ${rootdir}/harbor/docker-compose-linux-x86_64 /usr/bin/docker-compose

cp ${rootdir}/harbor/harbor.yml ${rootdir}/harbor/harbor.yml.bak

# 修改配置文件
cat >${rootdir}/harbor/harbor.yml <<EOF
hostname: $host
http:
  port: $port

harbor_admin_password: $harborpasswd

database:
  password: $dbpasswd
  max_idle_conns: 50
  max_open_conns: 100

data_volume: $datadir
clair:
  updaters_interval: 12
jobservice:
  max_job_workers: 10
notification:
  webhook_job_max_retry: 10
chart:
  absolute_url: disabled
log:
  level: info
  local:
    rotate_count: 50
    rotate_size: 200M
    location: $logdir
_version: 1.10.0

proxy:
  http_proxy:
  https_proxy:
  no_proxy:
  components:
    - core
    - jobservice
    - clair
EOF
# 安装
sleep 10s
chmod -R 777 ${rootdir}/harbor/install.sh
bash ${rootdir}/harbor/install.sh
sleep 10s

echo '确认Harbor是否正常启动......'
echo '检测中,请稍后......'
sleep 5s

cTaNerNum=$(docker ps | grep "harbor" | wc -l)

if [ $cTaNerNum -gt 4 ]; then
  echo 'Harbor服务启动成功...'
  echo '请确认以下服务信息: '
  echo 'Harbor服务相关信息为: '
  echo '=================================================='
  echo '=================================================='
  echo "Harbor服务访问地址: ${host}:${port}"
  echo "Harbor安装所在地址: ${rootdir}"
  echo "Harbor数据存放地址: ${datadir}"
  echo "Harbor备份地址为: ${backdir}"
  echo "Harbor密码为: ${harborpasswd}"
  echo "Database密码为: ${dbpasswd}"
  exit 0
else
  echo '=================================================='
  echo '=================================================='
  echo "Harbor 安装失败!!!"
  echo "docker compose 安装出现故障,请检查docker compose ....."
  echo '=================================================='
  echo '=================================================='
  exit 1
fi
