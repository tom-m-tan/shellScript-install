# 脚本摘要

维护人：ming.tan

创建时间：2022.2.10

更新时间：2023.2.10



1. 部署Docker



# 入参说明

| 参数       | 参数名称     | 类型 | 必填 | 默认值           | 备注 |
| ---------- | ------------ | ---- | ---- | ---------------- | ---- |
| rootdir    | 组件安装目录 | 字符 | 否   | /sie/docker/     |      |
| imagedir    | 数据目录     | 字符 | 否   | /var/lib/docker |      |
| packagedir | 安装包目录   | 字符 | 否   | /sie/packages    |      |



# 返回值说明

``` shell

result: 0  (0-执行成功  1-执行失败)
message: Error Message

```



# 脚本示例

``` shell

./docker.sh --imagedir=/var/lib/docker --rootdir=/sie/docker --packagedir=/opt/package

```



# 脚本逻辑

1. 检查rootdir是否存在，不存在创建文件夹；
2. 检查packagedir下安装包是否存在，没有则下载；
3. 检查imagedir是否存在，不存在创建文件夹；
4. 安装docker服务；
5. 配置docker服务自启动；
6. 配置edocker服务守护进程；
7. 更改默认docker配置文件；
8. 启用docker服务；
9. 输出安装信息；