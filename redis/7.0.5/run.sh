#!/bin/bash
#Redis部署
#默认参数
BootStart="/lib/systemd/system"
RunUser="sie-redis"
RunGroup="sie-serivces"
packagedir="/sie/package"
file="/sie/package/redis-7.0.5.tar.gz"
downurl="http://package.sieiot.com/redis/redis-7.0.5.tar.gz"
port=6379
params=$*

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

if [ $# -lt 1 ]; then
echo "当前脚本用于部署Redis
=====================================================
参数表如下:
----------------------------------------------------
--rootdir          选填参数,组件安装目录定义,默认/sie/redis
--logdir           选填参数,日志目录,默认/sie/redis/logs
--datadir          选填参数,数据目录,默认/sie/redis/data
--backdir          选填参数,备份目录,默认/sie/backup/redis
--password         *访问密码
--host             *服务IP,例如0.0.0.0
--port             选填参数,默认端口6379
=====================================================
"
exit
fi

rootdir=$(getparamValue rootdir)

datadir=$(getparamValue datadir)

logdir=$(getparamValue logdir)

backdir=$(getparamValue backdir)

password=$(getparamValue password)
checkparamValue  password $password

host=$(getparamValue host)
checkparamValue host $host

port=$(getparamValue port)

if [ "${port}" = "" ]
then
    port=6379
fi

if [ "${rootdir}" = "" ]
then
    rootdir=/sie/redis
fi

if [ "${logdir}" = "" ]
then
    logdir=/sie/redis/logs
fi

if [ "${datadir}" = "" ]
then
    datadir=/sie/redis/data
fi

if [ "${backdir}" = "" ]
then
    backdir=/sie/backup/redis
fi

echo "获得本次部署的参数如下:
  安装目录:   $rootdir
  数据目录:   $datadir
  日志目录：  $logdir
  备份目录:   $backdir
  访问密码:   $password
  服务IP：    $host
  端口 ：     $port "

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
    mkdir -p ${datadir}
else
    echo "目录已存在，请检查是否有数据，程序将自动退出"
    exit 9
fi

if [ ! -d ${backdir} ]
then
    mkdir -p ${backdir}
else
    echo "目录已存在，请检查是否有数据，程序将自动退出"
    exit 9
fi

if [[ ! -a "${file}" ]]; then
  echo "安装包不存在,下载中......"
  mkdir ${packagedir}
  wget ${downurl} -P ${packagedir}
  else
  echo "安装包存在"
fi


tar -xf ${packagedir}/redis-7.0.5.tar.gz -C ${packagedir}
mv ${packagedir}/redis-7.0.5/* $rootdir
cd $rootdir
mkdir ${logdir}
cp redis.conf redis.conf.bak

cat>redis.conf <<EOF
bind $host
protected-mode no
port $port
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize yes
supervised no
pidfile $rootdir/redis_6379.pid
loglevel notice
logfile "$logdir/redis6379.log"
databases 16
always-show-logo yes
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir $datadir
replica-serve-stale-data yes
replica-read-only yes
repl-diskless-sync no
repl-diskless-sync-delay 5
repl-disable-tcp-nodelay no
replica-priority 100
requirepass $password
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no
appendonly no
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
aof-load-truncated yes
aof-use-rdb-preamble yes
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128
latency-monitor-threshold 0
notify-keyspace-events ""
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64
hll-sparse-max-bytes 3000
stream-node-max-bytes 4096
stream-node-max-entries 100
activerehashing yes
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
hz 10
dynamic-hz yes
aof-rewrite-incremental-fsync yes
rdb-save-incremental-fsync yes
EOF

chown -R ${RunUser}:${RunGroup} ${rootdir}

cat>${BootStart}/redis.service <<EOF
[Unit]
Description=Redis
After=network.target
[Service]
User=${RunUser}
Group=${RunGroup}
Type=forking
PIDFile=${rootdir}/redis_6379.pid
ExecStart=${rootdir}/src/redis-server  ${rootdir}/redis.conf
ExecReload=/bin/kill -s HUP $MAINPID
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

systemctl  daemon-reload && systemctl start redis.service && systemctl  enable  redis.service

yum install -y zip
cat>>/var/spool/cron/root <<EOF
0 1 * * 7 zip ${backdir}/dump.rdb_\`date +\%Y-\%m-\%d-\%H-\%M-\%S\`.zip dump.rdb
EOF

cat>redis.sql <<EOF
HSET zuulAuthorization "/dyapi/baseDynamicApiController/save/insert_gushen_emp_performance_story_collection_SIE" "需求收集接口"
HSET zuulAuthorization "/api/base/sso/oauth2/get-user-info" "单点登录-OAuth2.0获取用户信息"
HSET zuulAuthorization "/governance/comm/sfGitlabController/countUpdate" "更新统计代码仓库-dev"
HSET zuulAuthorization "/platform/index/piRuleDispatchController/start-calc" "数据中台-规则参数日常调度计算"
HSET zuulAuthorization "/api/base/base-sso-oauth-config/get-login-type" "单点登录-获取应用支持的登录方式"
HSET zuulAuthorization "/scmabilitycenter/license/getLicense" "供应链license接口"
HSET zuulAuthorization "/pre/governance/comm/SfProjectStatisticController/record-work-hours" "善治工时每日工时变化统计"
HSET zuulAuthorization "/api/base/sso/oidc/refresh-token" "单点登录-OIDC协议刷新token"
HSET zuulAuthorization "/pre/governance/comm/sfGitlabController/userCountUpdate" "更新用户统计代码仓库-pre"
HSET zuulAuthorization "/base/api/sentinel-demo/fusing" "谷神-测试"
HSET zuulAuthorization "/api/base/base-login-config/get-login-info" "登录页配置信息查询"
HSET zuulAuthorization "/api/registration/signRewardRules/updateToExpired" "奖励规则 过期状态调度"
HSET zuulAuthorization "/dyapi/baseDynamicApiController/save/insert_sieiot_gushen_base_needs_collect_SIE" "动态表单-需求收集"
HSET zuulAuthorization "/api/file/iot-base-attachment/single-upload-biz-info-notoken" "文件服务上传文件(业务id关联)"
HSET zuulAuthorization "/governance/comm/sfGitlabController/userCountUpdate" "更新用户统计代码仓库-dev"
HSET zuulAuthorization "/mrf/intf/SendDate/SendDate1" "财务先生"
HSET zuulAuthorization "/dictionary/dic-items/get-dictype" "获取数据字典"
HSET zuulAuthorization "/governance/comm/sfJenkinsController/buildStatusUpdate" "善治"
HSET zuulAuthorization "/pre/governance/comm/SfProjectStatisticController/record-bug-count" "善治bug每日处理数量统计"
HSET zuulAuthorization "/platform/index/dmpAssetsPortal/getDataSourceRemote" "资产门户-资产概况"
HSET zuulAuthorization "/dynamicform/form/get-json-id" "获取动态表单json"
HSET zuulAuthorization "/datax/jobinfoController/create-tableDiagram" "历史血缘数据初始化"
HSET zuulAuthorization "/api/base/sso/oauth2/logout" "单点登录-OAuth2.0退出登录"
HSET zuulAuthorization "/diagnosisinfo/train/model/upload/clf—file" "工业手环模型文件上传"
HSET zuulAuthorization "/api/base/auth-dingtalk-login/scanCode/login" "钉钉扫码登录"
HSET zuulAuthorization "/mdfp/tmc/**" "商旅平台1111"
HSET zuulAuthorization "/api/base/base-tenant/register-tenant-notoken" "2021用户大会租户注册"
HSET zuulAuthorization "/gsearch/knowledge-es/**" "谷神-es"
HSET zuulAuthorization "/mdfp/tmc/getWeixinUserIdAndLogin" "商旅平台"
HSET zuulAuthorization "/pre/governance/comm/sfGitlabController/pushHookUpdate" "善治"
HSET zuulAuthorization "/api/base/auth-wx-login/callback" "企业微信扫码回调"
HSET zuulAuthorization "/bpm/bpmTaskService/autoUrgeAll" "流程催办"
HSET zuulAuthorization "/api/read/secpController/syncSecpAllUserCache" "同步所有用户到缓存"
HSET zuulAuthorization "/api/read/articlePersonDetailedController/timingRegisterCallBackFailData" "定时调度补偿游客注册回调失败数据"
HSET zuulAuthorization "/api/base/midea-synchro/**" "谷神-2021-美的同步数据"
HSET zuulAuthorization "/platform/index/portalAccessLog/save" "资产门户-系统访问量"
HSET zuulAuthorization "/api/base/sso/oidc/get-user-info" "单点登录-OIDC获取用户信息"
HSET zuulAuthorization "/platform/index/portalServerMonitorLog/save" "资产门户-服务器访问量"
HSET zuulAuthorization "/base/auth-wx-login/login-url" "企业微信应用登录"
HSET zuulAuthorization "/**/log/downloadLog" "日志下载"
HSET zuulAuthorization "/api/base/sso/oauth2/refresh-token" "单点登录-OAuth2.0协议刷新token"
HSET zuulAuthorization "/**/iot-base-attachment/getDownUrlByName/**" "谷神-附件重命名"
HSET zuulAuthorization "/api/registration/signInTemplateController/updateExpireSignTemplate" "签到模板失效数据调度"
HSET zuulAuthorization "/api/read/ArticleController/updateReleaseScheduling" "文章发布调度"
HSET zuulAuthorization "/api/read/ArticleController/sendUserIntegralSumYesterday" "推送C端用户昨日获取总积分"
HSET zuulAuthorization "/governance/comm/SfProjectStatisticController/record-bug-count" "善治dev环境每日数量统计"
HSET zuulAuthorization "/api/portal/**" "谷神"
HSET zuulAuthorization "/api/base/wx/cp/portal/**" "企业微信通讯录监控回调"
HSET zuulAuthorization "/api/base/sso/oauth2/chekc-token" "单点登录-OAuth2.0协议校验token"
HSET zuulAuthorization "/api/base/base-user/login" "登录接口"
HSET zuulAuthorization "/api/bms-comm/timedTaskController " "谷神-工作流"
HSET zuulAuthorization "/api/base/auth-wx-login/wxcp-info-byDomain" "app企业微信登录获取配置信息"
HSET zuulAuthorization "/api/registration/signInTemplateController/updateRedisSignTemplate" "将最新的签到模板数据加入redis"
HSET zuulAuthorization "/datax/jobLogController/sleep" "调度超时时间测试"
HSET zuulAuthorization "/api/dyreport/api/link/validate" "报表分享链接"
HSET zuulAuthorization "/api/base/auth-dingtalk-login/dt-info-byDomain" "钉钉登录获取配置信息"
HSET zuulAuthorization "/api/bms-comm/dingtalkLogin/avoidLogin" "瑞高钉钉免登录"
HSET zuulAuthorization "/**/visual/map/data/**" "大屏"
HSET zuulAuthorization "/**/only-office/save/file/**" "文件服务中心"
HSET zuulAuthorization "/pre/governance/comm/sfGitlabController/countUpdate" "更新统计代码仓库-pre"
HSET zuulAuthorization "/api/file/iot-base-attachment/single/file-upload-biz-no" "文件上传"
HSET zuulAuthorization "/api/file/iot-base-attachment/single/file-upload" "文件上传"
HSET zuulAuthorization "/iot-zt/sfTaskController/saveTaskHourDispatch" "迭代任务工时记录"
HSET zuulAuthorization "/api/read/copywritingController/updateToExpired" "文案过期调度"
HSET zuulAuthorization "/dataexport/export-data-record/update-status" "导入状态处理定时任务"
HSET zuulAuthorization "/**/contractVoyagePlanController/parsingCallBack/**" "/contractVoyagePlanController/parsingCallBack"
HSET zuulAuthorization "/api/base/resource/find-resource*396787565" "需求采集表格"
HSET zuulAuthorization "/governance/comm/sfGitlabController/pushHookUpdate" "善治"
HSET zuulAuthorization "/dynamicform/form-layout/getByFormId" "谷神-动态表单"
HSET zuulAuthorization "/gsearch/es-business/save-list" "知识库数据同步"
HSET zuulAuthorization "/dyapi/baseDynamicApiController/update/update_scp_purchase_req_SIE" 更新状态接口"
HSET zuulAuthorization "/api/base/sso/oauth2/login" "单点登录-OAuth2.0协议登录"
HSET zuulAuthorization "/dictionary/dic-items/get-dictype-remote" 测试"
HSET zuulAuthorization "/api/bms-comm/timedTaskController/syncPortInfo" "瑞高-同步港口数据"
HSET zuulAuthorization "/api/pidb/project-env/find-env-list" "善知善知保存问题表单下拉，获取环境列表"
HSET zuulAuthorization "/api/base/auth-wx-login/login-url" "企业微信登录"
HSET zuulAuthorization "/api/base/auth-wx-login/wxcp-info" "企业微信扫码获取配置信息"
HSET zuulAuthorization "/api/base/sso/oidc/login" "单点登录-OIDC协议登录"
HSET zuulAuthorization "/iot-zt/sfIterateController/statisticBurnData" "迭代燃尽图数据统计"
HSET zuulAuthorization "/api/base/sso/oidc/logout" "单点登录-OIDC退出登录"
HSET zuulAuthorization "/api/base/base-user/send-sso-email-validator-code" "单点登录-发送邮箱验证码"
HSET zuulAuthorization "/es-business/save-list " "知识库数据同步"
HSET zuulAuthorization "/api/task/taskController/updateToExpired" "任务维护过期调度"
HSET zuulAuthorization "/api/base/sso/token" "code  换取 token和刷新token"
HSET zuulAuthorization "/api/base/auth-dingtalk-login/login" "钉钉登录接口"
HSET zuulAuthorization "/api/pidb/problem-sheet/save-problem-sheet" "善知保存问题清单白名单"
HSET zuulAuthorization "/api/base/sso/oidc/token" "单点登录-OIDC协议获取token"
HSET zuulAuthorization "/api/base/sso/oidc/chekc-token" 单点登录-OIDC协议校验token"
HSET zuulAuthorization "/dyapi/baseDynamicApiController/save/insert_gushen_demo_questionnaire_line" "谷神-动态demo"
HSET zuulAuthorization "/api/base/sso/oauth2/token" "单点登录-OAuth2.0协议获取token"
HSET zuulAuthorization "/api/base/auth-wx-login/**" "企业微信登录重定向"
HSET zuulAuthorization "/api/base/sso/simple-user" "校验token"
HSET zuulAuthorization "/api/base/base-user/send-sso-validator-code" "单点登录-发送短信验证码"
HSET zuulAuthorization "/pre/governance/comm/sfJenkinsController/buildStatusUpdate" "善治"
HSET zuulAuthorization "/api/base/actuator/redis/info" "测试redis"
HSET zuulAuthorization "/governance/comm/SfProjectStatisticController/record-work-hours" "善治dev环境工时统计"
HSET zuulAuthorization "/api/external/personnel/**" 数据同步白名单"
HSET zuulAuthorization "/platform/index/dmpProjectBanner/saveSchedule" "资产门户-项目看板"
HSET zuulAuthorization "/api/pidb/share-link/view" "善知文档分享页白名单"
HSET zuulAuthorization "/bpm/service/model/**" "流程模型"
HSET zuulAuthorization "/services/find-service-route" "网关路由信息111"
HSET zuulAuthorization "/api/base/base-user/send-validator-code" "登录时发送验证码"
HSET zuulAuthorization /api/base/base-user/get-enryption  获取加密信息接口

SET gs:snowflake:datacenter 4
EOF

cat redis.sql | ${rootdir}/src/redis-cli -a ${password} -p $port

if check_port $port
then
    echo "${port}端口存在"
else
    echo "${port}端口不存在"
fi


systemctl  status  redis.service

if (( $? != 0 )) ; then
  echo -e "\033[31m redis未正常启动 \033[0m"
  exit 9
elif [ $a == 0 ] ;then
  echo "redis已启动"
fi


echo -e  "\033[31m ========================
  Redis部署完成,并初始完数据
  版本: redis-7.0.5
  访问地址： $host:$port
  访问密码:  $password
 ======================== \033[0m"
