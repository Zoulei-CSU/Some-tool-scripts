## OneCloud常用服务

------

### 1.安装轻量化Docker可视化面板

```shell
# 装Docker可视面板
# --restart always 这个是跟随docker服务一起启动，避免docker重启后，容器没有启动的尴尬
# -p 这里是映射到外网的端口 自己看着改 8081:端口
# -d 是代表在后台启动服务
# -v 挂载宿主机的一个目录。
docker run --restart always --name fast -p 8081:8081 -d -v /var/run/docker.sock:/var/run/docker.sock wangbinxingkong/fast
```



### 2.安装CasaOS

```shell
#安装casaos
#casaos官网：https://www.casaos.io
curl -fsSL https://get.casaos.io | bash
#安装完成后在浏览器访问 http://服务器IP地址或域名
```



### 3.安装Openwrt的Docker

Docker下装openwrt，可使用这个镜像：https://hub.docker.com/r/xuanaimai/onecloud

第2步创建网络，要根据自己的网络环境设置网关和网段。

```shell
# 1.打开网卡混杂模式
ip link set eth0 promisc on

# 2.创建网络
docker network create -d macvlan --subnet=172.16.50.0/24 --gateway=172.16.50.1 -o parent=eth0 macnet

# 3.拉取 OpenWRT 镜像
docker pull xuanaimai/onecloud:21-09-15

# 4.创建容器
docker run -itd --name=OpenWRT --restart=always --network=macnet --privileged=true xuanaimai/onecloud:21-09-15 /sbin/init
# 默认密码是 password
```

更多教程，也可参考 https://www.right.com.cn/forum/thread-7479383-1-1.html

