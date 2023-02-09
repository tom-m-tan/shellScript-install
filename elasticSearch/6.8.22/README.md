# 脚本摘要

维护人：檀明

创建时间：

更新时间：2023.01.31



1. 安装elastic


# 入参说明

| 参数     | 参数名称     | 类型   | 必填 | 默认值    | 备注                 |
| -------- | ------------ | ------ | ---- | --------- | -------------------- |
| --rootdir     | 组件安装目录 | 字符串 | 否   | 默认/sie/elastic/ |  组件安装目录定义      |
| --datadir     | 存储数据目录 | 字符串 | 否   | 默认/sie/elastic/data | 数据存储目录定义    |
| --packagedir     | 安装包存储目录    | 字符串   | 否   |  默认/sie/packagedir   | 安装包指定目录定义 |
| --logdir     | 服务端口 | 数值 | 否   | 默认/sie/elastic/logs |      日志存储目录定义  |
| --backdir     | 服务IP | 字符串 | 否   | 默认/sie/backup/elasticback  |     备份目录定义    |
| --port     | 定义服务端口  | 数值   | 否   | 9200        |  elastic服务端口定义      |
| --host     | 需要安装主机地址 | 字符串 | 是   | 无默认值 | 例如: 192.168.1.10;本机IP |
| --javahome     | 运行JAVA_HOME目录    | 数值   | 是   | 0         | java运行home目录指定 |





# 返回值说明

``` shell

result：0 # 0=执行成功；1=不成功；
message：succeed # 执行成功
IP: 127.0.0.1 # 服务所在服务器地址
Port：9200 # 服务所使用端口

```



# 脚本示例

``` shell

./run.sh --"host=127.0.0.1" --javahome="/sie/jdk/java18.0.1" --port="9300"  --rootdir="/sie/elastic/" --datadir="/sie/elastic/data" --packagedir="/sie/packagedir" --logdir="/sie/elastic/logs" --backdir=/sie/backup/elasticback 

```



# 脚本逻辑

1. 检查rootdir是否存在，不存在创建文件夹；
2. 检查datadir是否存在，不存在创建文件夹；
3. 检查服务暴露端口是否被占用；
4. 安装elastic服务；
5. 配置elastic服务自启动；
6. 配置elastic服务守护进程；
7. 更改默认elastic配置文件；集群则需要设置集群形式；
8. 启用elastic服务；
9. 输出服务版本；
10. 输出服务访问地址；