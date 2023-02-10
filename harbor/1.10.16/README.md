# 脚本摘要

维护人：ming.tan

创建时间：2022.2.10

更新时间：2022.2.10



1. 安装Harbor二进制


# 入参说明

| 参数     | 参数名称     | 类型   | 必填 | 默认值    | 备注                 |
| -------- | ------------ | ------ | ---- | --------- | -------------------- |
| --rootdir     | 组件安装目录定义 | 字符串 | 否   | 默认/sie/harbor/ |  组件运行目录     |
| --packagedir     | 安装包存储目录定义 | 字符串 | 否   | 默认/sie/packagedir | 安装包存放地址  |
| --logdir     | Harbor日志目录 | 字符串 | 否   | 默认/sie/harbor/logs |   日志目录    |
| --datadir     | 存储数据目录  | 字符串   | 否   | 默认/sie/harbor/data   |    存储数据目录  |
| --backdir     | 数据备份目录     | 字符串   | 否   | 默认/sie/backup/harborback   | 数据备份目录 |       |
| --host | 主机IP     | 数值 | 是   |           | 例如: 192.168.1.10;本机IP      |
| --port | 服务端口     | 数值 | 否   | 默认 80     |  可传参定义  |
| --harborpasswd | harbor服务密码     | 字符串 | 否   | 默认密码:Harbor12345   | 传参替换该密码 |
| --dbpasswd | 数据库服务密码     | 字符串 | 否   | 默认密码db@Admin123   | 传参替换该密码     |




# 返回值说明

``` shell

✔ ----Harbor has been installed and started successfully.----

    Harbo服务相关信息为: 
    ==================================================
    Harbor服务访问地址: 192.168.1.91:80
    Harbor安装所在地址: /sie/harbor
    Harbor数据存放地址: /sie/harbor/data
    Harbor密码为: Harbor12345
    Database密码为: db@Admin123

```



# 脚本示例

``` shell

./run.sh --packagedir="/opt/package" --host="192.168.1.91" --port="8080" --harborpasswd="harbor@123@" --dbpasswd="admin@123" --rootdir="/opt/harbor" --logdir="/var/logs" --datadir="/harbor/data" --backdir="/sie/backup/harbor"

```



# 脚本逻辑

1. 检查rootdir是否存在，不存在创建文件夹；
2. 检查datadir是否存在，不存在创建文件夹；
3. 定义服务安装主机所在IP；
4. 定义服务安装主机所使用端口；
5. 检测docker服务是否安装；
6. 检测docker-compose是否安装；
7. 判断docker-compose安装包是否存在，否则下载；
8. 配置docker-compose；
9. 判断Harbor安装包是否存在，否则下载；
10. 配置harbor安装包；
11. 启动harbor服务；
12. 输出安装过程信息；
13. 输出服务相关信息；