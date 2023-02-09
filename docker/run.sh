#!/bin/bash
# author: ming.tan
# date: 2023.2.8
BootStart="/lib/systemd/system"
RunUser="sie-docker"
RunGroup="sie-serivces"
dockerVersion=20.10.5
downurl="http://package.sieiot.com/docker/docker-${dockerVersion}.tgz"
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

if [ $# -lt 0 ]; then
echo "当前脚本用于部署Docker
=====================================================
参数表如下:
----------------------------------------------------
--rootdir          选填参数,组件安装目录定义,默认/sie/docker
--packagedir       选填参数,备份目录,默认/sie/packagedir
--imagedir         选填参数,数据目录,默认/sie/docker/data
=====================================================
"
exit
fi

rootdir=$(getparamValue rootdir)

packagedir=$(getparamValue rootdir) 

imagedir=$(getparamValue datadir)

if [ "${rootdir}" = "" ]
then
    rootdir=/sie/docker
fi

if [ "${packagedir}" = "" ]
then
    packagedir=/sie/packagedir
fi

if [ "${imagedir}" = "" ]
then
    imagedir=${rootdir}/data
fi


docker ps &>/dev/null

if [ $? -eq 0 ];then
    echo "docker 已安装,请检查......"
    exit 1 
fi

echo "正在进行docker安装......"

if [[ ! -f "${packagedir}docker-${dockerVersion}.tgz" ]]; then
  echo "检索安装包ing,请稍后....."
  mkdir -p ${packagedir}
  wget -c -P ${packagedir} ${downurl} 
  else
  echo '安装包存在......'
  echo '======================================================='
  echo '正在解压安装......'
fi

# 解压安装
mkdir -p ${rootdir}
chown -R ${RunUser}:${RunGroup} ${rootdir}
tar -xf ${packagedir}/docker-${dockerVersion}.tgz  -C ${rootdir}

if [ -f /usr/bin/docker ];then
    rm -rf /usr/bin/docker
fi

ln -s ${rootdir}/docker/docker /usr/bin/docker
mkdir -p ${imagedir}
chown -R ${RunUser}:${RunGroup} ${imagedir}
CONdocker=/etc/docker
mkdir -p ${CONdocker}
chown -R ${RunUser}:${RunGroup} ${CONdocker}

cat > ${CONdocker}/daemon.json <<EOF
        {
           "registry-mirrors": ["https://b9pmyelo.mirror.aliyuncs.com"],
           "graph": "${imagedir}"
        }
EOF

cat > ${BootStart}/docker.service <<EOF
[Unit]
Description=docker
[Service]
Environment="PATH=${rootdir}/docker:/bin:/sbin:/usr/bin:/usr/sbin"
ExecStart=${rootdir}/docker/dockerd 
ExecStartPost=/sbin/iptables -I FORWARD -s 0.0.0.0/0 -j ACCEPT
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target

EOF

systemctl  daemon-reload && systemctl start docker && systemctl enable docker
sleep 20s
docker ps &>/dev/null
if [ $? -eq 0 ];then
    
    echo '======================================================='
    echo '======================================================='
    echo 'docker 安装成功!!!'
    echo "镜像&容器存储地址: ${imagedir}"
    echo "docker工作目录: ${rootdir}"
    echo "安装包地址: ${packagedir}"
    echo '======================================================='
    echo '======================================================='
    systemctl status docker
    exit 0
else
    echo '======================================================='
    echo 'docker 安装失败,请检查系统日志!!!'
    echo '======================================================='
    systemctl status docker
fi