# 脚本摘要

维护人：檀明

创建时间：2023.01.31

更新时间：



1. 初始化JVM


# 入参说明

| 参数     | 参数名称     | 类型   | 必填 | 默认值    | 备注                 |
| -------- | ------------ | ------ | ---- | --------- | -------------------- |
| rootdir     | 组件安装目录 | 字符串 | 否   | /sie/jdk |   组件运行目录定义                    |
| packagedir     | 组件安装包的路径 | 字符串 | 否   | /sie/packagedir |    组件安装包所在目录  |



# 返回值说明

``` shell

result：0 # 0=执行成功；1=不成功；
JVM初始化成功！！！
rootdir:  /sie/jdk/
packagedir:  /sie/packagedir

```



# 脚本示例

``` shell

./run.sh --rootdir="/sie/jdk/" --datadir="/sie/packagedir"

```



# 脚本逻辑

1. 检查rootdir是否存在，不存在创建文件夹；
2. 检查datadir是否存在，不存在创建文件夹；
3. 安装jdk；
4. 配置jdk服务自启动；
5. 配置jdk服务守护进程；
6. 启用jdk服务；
7. 调优JVM；
8. 数据目录初始化；
9.  输出初始化成功信息；