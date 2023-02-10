# 脚本摘要

维护人：ming.tan

创建时间：2022.2.10

更新时间：2022.2.10



1. redis安装


# 入参说明

| 参数     | 参数名称     | 类型   | 必填 | 默认值    | 备注                 |
| -------- | ------------ | ------ | ---- | --------- | -------------------- |
| rootdir     | 组件安装目录 | 字符串 | 是   | /sie/redis/ |  组件安装目录定义                    |
| datadir     | 数据目录 | 字符串 | 是   | /sie/redis/data | 数据存储目录定义 
| logdir     | 日志目录 | 字符串 | 是   | /sie/redis/logs |   日志目录定义                |
| host     | 服务IP | 字符串 | 是   | 127.0.0.1 |   内网IP                  |
| backdir     | 备份目录 | 字符串 | 是   | sie/backup/redis |   备份目录定义                |
| port     | 服务端口 | 数值 | 否   | 6379 |    默认6379               |                   |
| passwd     | redis密码 | 字符串 | 是   | xxxx |                    |
| unstall | 卸载已安装     | 数值 | 否   | 0          | 0=不生效；1=生效       |




# 返回值说明

``` shell

result：0 # 0=执行成功；1=不成功；
message：succeed # 执行成功
输出服务信息：服务访问IP:端口
输出redis访问账号密码：user=xxxx；passwd=xxxx

```



# 脚本示例

``` shell

./run.sh --rootdir=/sie/redis --logdir=/sie/redis/logs --datadir=/sie/redis/data --backdir=/sie/backup/redis --password=123456 --host=0.0.0.0 --port=6379
```



# 脚本逻辑

1. 检查rootdir是否存在，不存在创建文件夹；
2. 检查datadir是否存在，不存在创建文件夹；
3. 检查服务暴露端口是否被占用；
4. 安装redis服务；
5. 配置redis服务自启动；
6. 配置redis服务守护进程；
7. 更改默认redis配置文件；设置账号密码。
8. 启用redis服务；
9. 输出服务版本；
10. 输出服务访问地址；
11. 输出redis相关登陆信息；