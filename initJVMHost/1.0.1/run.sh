#!/bin/bash
# author: ming.tan
# date: 2023.2.2
params=$*
urldown="http://package.sieiot.com/jdk/jdk1.8.0_191.tar.gz"
EvnPath="/etc/profile.d"
JdkName="jdk1.8.0_191"
GetValue() {
    re=$(echo $params | awk -F "--$1=" '{print $2}' | awk '{print $1}')
    echo $re
}

CheckValue() {
    if [ "$2" = "" ]; then
        echo "错误:参数 --$1 的值不能为空,程序将退出"
        exit
    fi
}

rootdir=$(GetValue rootdir)
packagedir=$(GetValue packagedir)

if [ "$rootdir" = "" ]; then
    rootdir="/sie/jdk"
fi

if [ "$packagedir" = "" ]; then
    packagedir="/sie/packagedir"
fi

if [ ! -f "$packagedir/${JdkName}.tar.gz" ]; then
    wget -c -P ${packagedir}/ ${urldown}
fi

if [ -d "$rootdir/jdk/${JdkName}/bin" ];then
        echo 'jdk已安装,jdk信息为:'
        echo '=================================='
        echo "$(java -version)" 
        exit 0
fi

mkdir -p ${rootdir}
tar -zxf ${packagedir}/${JdkName}.tar.gz -C ${rootdir}
cat >${EvnPath}/jdkexport.sh <<EOF
export JAVA_HOME=$rootdir/${JdkName}
export CLASSPATH=.:$rootdir/${JdkName}/jre/lib/rt.jar:$rootdir/${JdkName}/lib/dt.jar:$rootdir/${JdkName}/lib/tools.jar
export PATH=$PATH:$rootdir/${JdkName}/bin
EOF
source ${EvnPath}/jdkexport.sh


function Result() {
    java -version &>/dev/null
    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}
chmod -R 777 ${rootdir}
java -version &>/dev/null
if [ $? -eq 0 ]; then
echo '=================================='

echo "$(java -version)
JVM初始化成功!!!
rootdir:  $rootdir
packagedir:  $packagedir"
Result
exit 0
else
    echo "初始化失败！！！"
fi